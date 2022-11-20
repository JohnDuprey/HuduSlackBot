function Invoke-ProcessHuduSubscription {
    Param($Subscription) 
    try {
        Import-Module PSSlack
        Set-PSSlackConfig -Token $env:SlackBotToken -NoSave

        Write-Output 'Activity Subscription Durable'
        #Write-Output ($Subscription | ConvertTo-Json)

        Initialize-HuduApi

        $StartDate = Get-Date -UFormat '%F'
        $Actions = $Subscription.Actions -split ','

        # TODO: Optimize activity log query when API allows filtering by record_type and asset_layout_id
        $LogQuery = @{
            StartDate = $StartDate
        }
        if ($Subscription.RecordType -eq 'Asset') {
            #$LogQuery.AssetLayoutId = $Subscription.AssetLayoutId
        }
        
        $ActivityLogs = Get-HuduActivityLogs @LogQuery | Sort-Object id 

        Write-Output "Searching logs for $Actions $($Subscription.RecordType)"
        $Logs = foreach ($Action in $Actions) {
            $ActivityLogs | Where-Object { $_.record_type -eq $Subscription.RecordType -and ($Action -eq 'all' -or $Action -eq $_.action) -and (!$Subscription.LastActivityId -or $Log.id -gt $Subscription.LastActivityId) } 
        }
    
        $ErrorsDetected = $false

        if ($Logs) {
            foreach ($Log in $Logs) {
                if ($Subscription.RecordType -eq 'Asset') {
                    $Layout = Get-HuduAssetLayouts -LayoutId $Log.asset_layout_id
                    $RichFields = $Layout.fields | Where-Object { $_.field_type -eq 'RichText' }
                    $Asset = Get-HuduAssets -Id $Log.record_id
                    #Write-Output ($Asset | ConvertTo-Json)
                    if ($Asset.asset_layout_id -ne $Subscription.AssetLayoutId -and $Subscription.AssetLayoutId -gt 0) { continue }
                    
                    $RichTextFields = [system.collections.generic.list[string]]::new()
                    #Write-Output ($Asset.fields | ConvertTo-Json)
                    $Fields = foreach ($Field in $Asset.fields) {
                        if ($Field.value -and $Field.value -ne '[]') {
                            try { 
                                if ($RichFields.label -contains $Field.label) {
                                    $MarkdownOptions = @{
                                        Content           = $Field.value
                                        UnknownTags       = 'Bypass'
                                        SmartHrefHandling = $true
                                    }
                                    $Markdown = ConvertFrom-HTMLToMarkdown @MarkdownOptions | ConvertTo-SlackLinkMarkdown
                                    $RichTextFields.Add(("*{0}*`n{1}" -f $Field.label, $Markdown)) | Out-Null
                                    continue
                                }
                                else {
                                    $FieldTag = $Field.value | ConvertFrom-Json -ErrorAction Stop
                                    if ($FieldTag.id) {
                                        $Value = '<{0}{1}|{2}>' -f $env:HuduBaseUrl, $FieldTag.url, $FieldTag.name
                                    }
                                    else {
                                        $Value = $Field.value
                                    }
                                }
                            }
                            catch { $Value = $Field.value }

                            "*{0}*`n{1}" -f $Field.Label, $Value
                        }
                    }
                    $Blocks = New-SlackMessageBlock -Type section -Text ( "*Activity Log Subscription*`n{0} Asset {1}: <{2}|{3}>`n`n*Company*`n{4}" -f $Asset.asset_type, $Action, $Asset.url, $Asset.name, $Asset.company_name ) -Fields $Fields 

                    if ($RichTextFields) {
                        foreach ($RichTextField in $RichTextFields) {
                            $Blocks = $Blocks | New-SlackMessageBlock -Type section -Text $RichTextField
                        }
                    }
                    $Blocks | ConvertTo-Json
                }
                else {
                    if ($Log.company_name) {
                        $Company = '`n`n*Company*`n<{0}|{1}>' -f $Log.company_url, $Log.company_name
                    }
                    else {
                        if ($Log.record_type -eq 'Asset') {
                            $Company = "`n`n*Global KB*"
                        }
                    }

                    $Blocks = New-SlackMessageBlock -Type section -Text ( "*Activity Log Subscription*`n{0} {1}: <{2}|{3}> {4}" -f $Subscription.RecordType, $Action, $Log.record_url, $log.record_name, $Company)
                }
                $Timestamp = $Log.created_at | Get-Date -UFormat '%s'
                $ContextElements = @(
                    @{
                        type = 'mrkdwn'
                        text = "$($log.user_name) <!date^$Timestamp^$($Action) {date_pretty}|$($Log.formatted_datetime)>"
                    }
                )
                $Blocks = $Blocks | New-SlackMessageBlock -Type context -Elements $ContextElements | New-SlackMessageBlock -Type divider

                #Write-Output ($Blocks | ConvertTo-Json -Depth 10)
                $LogMessage = @{
                    Channel = $Subscription.ChannelID
                    Blocks  = $Blocks
                    Text    = ('Activity Log - {0} {1}: {2}' -f $Subscription.RecordType, $Action, $log.record_name )
                }
                try { 
                    $LogStatus = Send-SlackMessage @LogMessage 
                    if ($LogStatus.ok) {
                        $LastActivityId = $Log.id
                    }
                    else {
                        $ErrorsDetected = $true
                        break
                    }
                }
                catch {
                    Write-Host "Exception sending activity log: $($_.Exception.Message)"
                }
            }

            if (!$ErrorsDetected) {
                $Subscription.LastActivityId = $LastActivityId
                
                $SubscriptionUpdate = @{
                    TableName    = 'HuduActivitySubscriptions'
                    RowKey       = $Subscription.RowKey
                    PartitionKey = $Subscription.PartitionKey                    
                    TableRow     = $Subscription
                }
                Set-SlackBotData @SubscriptionUpdate
            }
            else {
                $ErrorConvo = @{
                    Method = 'conversations.open'
                    Body   = @{
                        users     = $Subscription.CreatedBy
                        return_im = $true
                    }
                }
                $Conversation = Send-SlackApi @ErrorConvo
                if ($Conversation.ok) {
                    $ErrorMessage = @{
                        Channel = $Conversation.channel.id
                        Text    = ('An error occurred while trying to send activity logs to the channel <#{0}>. Make sure I can post to that channel by inviting me!' -f $Subscription.ChannelID)
                    }
                    Send-SlackMessage @ErrorMessage | Out-Null
                }
            }
        }
        else {
            Write-Output 'No events to process'
        }
        
    }
    catch {
        Write-Output "Exception processing subscriptions: $($_.Exception.Message)"
    }
}

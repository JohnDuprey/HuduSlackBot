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
            $ActivityLogs | Where-Object { $_.record_type -eq $Subscription.RecordType -and $Action -eq $_.action -and ($null -eq $Subscription.LastActivityId -or $_.id -gt $Subscription.LastActivityId) }
        }

        $ErrorsDetected = $false

        if ($Logs) {
            foreach ($Log in $Logs) {
                if ($Subscription.RecordType -eq 'Asset') {
                    $Layout = Get-HuduAssetLayouts -LayoutId $Log.asset_layout_id
                    $RichFields = $Layout.fields | Where-Object { $_.field_type -eq 'RichText' }
                    $DateFields = $Layout.fields | Where-Object { $_.field_type -eq 'Date' }
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
                                    $RichText = "*{0}*`n{1}" -f $Field.label, $Markdown
                                    $RichText = $RichText.substring(0, [System.Math]::Min(3000, $RichText.Length))
                                    $RichTextFields.Add($RichText) | Out-Null
                                    continue
                                }

                                elseif ($DateFields.label -contains $Field.label) {
                                    $Value = $Field.value | Get-Date -UFormat '%F'
                                }

                                else {
                                    $FieldTags = $Field.value | ConvertFrom-Json -ErrorAction Stop
                                    $Values = foreach ($FieldTag in $FieldTags) {
                                        if ($FieldTag.id) {
                                            '<{0}{1}|{2}>' -f $env:HuduBaseDomain, $FieldTag.url, $FieldTag.name
                                        } else {
                                            $Field.value
                                        }
                                    }
                                    $Value = $Values -join ' '
                                }
                            } catch { $Value = $Field.value }

                            "*{0}*`n{1}" -f $Field.Label, $Value
                        }
                    }
                    $Blocks = New-SlackMessageBlock -Type section -Text ( "*Activity Log Subscription*`n{0} Asset {1}: <{2}|{3}>`n`n*Company*`n<{4}|{5}>" -f $Asset.asset_type, $Action, $Asset.url, $Asset.name, $Log.record_company_url, $Log.company_name ) -Fields $Fields

                    if ($RichTextFields) {
                        foreach ($RichTextField in $RichTextFields) {
                            $Blocks = $Blocks | New-SlackMessageBlock -Type section -Text $RichTextField
                        }
                    }
                    #$Blocks | ConvertTo-Json
                } else {
                    if ($Log.company_name) {
                        $Company = '<{0}|{1}>' -f $Log.record_company_url, $Log.company_name
                    } else {
                        if ($Log.record_type -eq 'Article') {
                            $Company = 'Global KB'
                        }
                    }

                    $Blocks = New-SlackMessageBlock -Type section -Text ( "*Activity Log Subscription*`n{0} {1} in {2}: <{3}|{4}>" -f $Subscription.RecordType, $Action, $Company, $Log.record_url, $log.record_name)
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
                    } else {
                        $ErrorsDetected = $true
                        break
                    }
                } catch {
                    Write-Error "Exception sending activity log: $($_.Exception.Message)"
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
            } else {
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
        } else {
            Write-Output 'No events to process'
        }

    } catch {
        Write-Output "Exception processing subscriptions: $($_.Exception.Message)"
    }
}

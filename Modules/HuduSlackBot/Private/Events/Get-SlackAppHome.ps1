function Get-SlackAppHome {

    # Get subscription list
    $SubQuery = @{
        TableName    = 'HuduActivitySubscriptions'
        PartitionKey = 'Subscription'
    }

    # Get Hudu info
    try {
        Initialize-HuduApi
        $Info = Get-HuduAppInfo -ErrorAction SilentlyContinue
    }
    catch {
    
    }
    $Subscriptions = Get-SlackBotData @SubQuery

    $HuduLinkElement = @{
        Type     = 'button'
        ActionId = 'OpenHudu'
        Text     = ':link: Open Hudu'
        Url      = $env:HuduBaseUrl
        Value    = 'Open-HuduWebsite'
    }

    $AddSubscriptionElement = @{
        Type     = 'button'
        ActionId = 'Open-HuduSubscriptionModal'
        Text     = ':bell: Add Activity Subscription'
        Style    = 'primary'
        Value    = 'Open'
    }


    $HeaderBlock = @{
        BlockId   = 'ViewHeader'
        Type      = 'header'
        PlainText = 'HuduBot - Slack bot for Hudu'
    }
    $Blocks = New-SlackMessageBlock @HeaderBlock

    if (!$Info) {
        $ActionButtons = New-SlackMessageBlockElement @HuduLinkElement
        $ActionsBlock = @{
            BlockId  = 'ActionsBlockId'
            Type     = 'actions'
            Elements = $ActionButtons
        }
        $Blocks = $Blocks | New-SlackMessageBlock @ActionsBlock

        $WarningBlock = @{
            BlockId = 'WarningBlockId'
            Type    = 'section'
            Text    = ':warning: We are unable to access the Hudu API, please check your HuduAPIKey setting.'
        }
        $Blocks = $Blocks | New-SlackMessageBlock @WarningBlock
    }
    else {
        $HeaderContextElements = @(
            @{
                type = 'mrkdwn'
                text = ('Server version: {0}' -f $Info.Version)
            }
        )
        $HeaderContextBlock = @{
            Type     = 'context'
            Elements = $HeaderContextElements
        }
        $Blocks = $Blocks | New-SlackMessageBlock -Type divider | New-SlackMessageBlock @HeaderContextBlock

        $UpdateCheck = Get-HuduServerUpdate -Version $Info.Version
        if (!$UpdateCheck.Current) {
            $WarningBlock = @{
                BlockId = 'WarningBlockId'
                Type    = 'section'
                Text    = (':warning: Your Hudu server is not running the latest version. {0}' -f $UpdateCheck.ReleaseLink)
            }
            $Blocks = $Blocks | New-SlackMessageBlock @WarningBlock
        }

        $ActionButtons = New-SlackMessageBlockElement @HuduLinkElement | New-SlackMessageBlockElement @AddSubscriptionElement
        $ActionsBlock = @{
            BlockId  = 'ActionsBlockId'
            Type     = 'actions'
            Elements = $ActionButtons
        }
        $Blocks = $Blocks | New-SlackMessageBlock @ActionsBlock
           
        if ($Subscriptions) {
            $ActivityLogHeader = @{
                BlockId   = 'SubscriptionBlockId'
                Type      = 'header'
                PlainText = 'Activity Log Subscriptions' 
            }
            $Blocks = $Blocks | New-SlackMessageBlock -Type divider | New-SlackMessageBlock @ActivityLogHeader

            foreach ($Subscription in $Subscriptions) {

                # Subscription fields
                $Timestamp = Get-Date $Subscription.Timestamp.DateTime -UFormat '%s'
                $DateTime = Get-Date $Subscription.Timestamp.DateTime -UFormat '%F'

                $SubFields = [system.collections.generic.list[string]]@(
                        ("*Type:*`n {0}" -f $Subscription.RecordType)
                        ("*Action:*`n {0}" -f $Subscription.Actions)
                        ("*Channel:*`n <#{0}>" -f $Subscription.ChannelID)
                )
               
                if ($Subscription.RecordType -eq 'Asset') {
                    $SubFields.Add("*Asset Layout:*`n {0}" -f $Subscription.AssetLayoutName) | Out-Null
                }

                # Subscription overflow menu
                $OverflowBlockElement = @{
                    Type     = 'overflow'
                    ActionId = 'Remove-HuduActivitySubscription'
                    Options  = @{ $Subscription.RowKey = 'Delete' }
                }
                $SubOverflow = New-SlackMessageBlockElement @OverflowBlockElement 
                $SubFieldBlock = @{
                    Type      = 'section'
                    Fields    = $SubFields
                    Accessory = $SubOverflow
                }

                # Subscription context
                $ContextElements = @(
                    @{
                        type = 'mrkdwn'
                        text = ('Created by <@{0}>' -f $Subscription.CreatedBy)
                    }
                    @{
                        type = 'mrkdwn'
                        text = "Last Update: <!date^$($Timestamp)^{date_pretty}|$DateTime>"
                    }
                )
                $ContextBlock = @{
                    Type     = 'context'
                    Elements = $ContextElements
                }

                # Assemble blocks to build subscription view
                $Blocks = $Blocks | New-SlackMessageBlock -Type divider | New-SlackMessageBlock @SubFieldBlock | New-SlackMessageBlock @ContextBlock
            }
        }
    }

    return $Blocks
}


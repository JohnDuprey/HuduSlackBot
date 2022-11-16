function Get-SlackAppHome {
    Param(
        $SlackEvent
    )

    #$SlackEvent | ConvertTo-Json -Depth 10
    if ($SlackEvent.event.tab -eq 'home') {

        # Get subscription list
        $SubQuery = @{
            TableName    = 'HuduActivitySubscriptions'
            PartitionKey = 'Subscription'
        }
        $Subscriptions = Get-SlackBotData @SubQuery

        $ActionButtons = New-SlackMessageBlockElement -Type button -ActionId 'OpenHudu' -Text ':link: Open Hudu' -Value 'value_hudu' -Url $env:HuduBaseUrl `
        | New-SlackMessageBlockElement -Type button -ActionId 'ModalActivitySub' -Text ':bell: Add Activity Subscription' -Style primary -Value 'value_activitysub'
        
        $Blocks = New-SlackMessageBlock -BlockId 'HeaderBlockId' -Type header -Text 'HuduBot - Slack bot for Hudu' `
        | New-SlackMessageBlock -Type divider `
        | New-SlackMessageBlock -BlockId 'ActionsBlockId' -Type actions -Elements $ActionButtons

        if ($Subscriptions) {
            $Blocks = $Blocks | New-SlackMessageBlock -Type divider `
            | New-SlackMessageBlock -BlockId 'SubscriptionBlockId' -Type header -Text 'Activity Log Subscriptions' 
            foreach ($Subscription in $Subscriptions) {
                $Timestamp = Get-Date $Subscription.Timestamp.DateTime -uformat "%s"
                $SubFields = [system.collections.generic.list[string]]@(
                    "*Type:* $($Subscription.ActivityType)"
                    "*Action:* $($Subscription.Actions)"
                    "*Channel:* <#$($Subscription.ChannelID)>"
                )

                if ($Subscription.ActivityType -eq 'Assets') {
                    $SubFields.Add("*Asset Type*: $($Subscription.AssetTypeName)")
                }

                $ContextElements = @(
                    @{
                        type="mrkdwn"
                        text="<!date^$Timestamp^Created {date_short_pretty}|timeerror> by <@$($Subscription.CreatedBy)>"
                    }
                )

                $elements_of = New-SlackMessageBlockElement -Type overflow -ActionId "subscription-$($Subscription.RowKey)" -Options @{ delete = 'Delete' }
                $Blocks = $Blocks | New-SlackMessageBlock -Type divider `
                | New-SlackMessageBlock -Type section -Fields $SubFields -Accessory $elements_of `
                | New-SlackMessageBlock -Type context -Elements $ContextElements
                #$User = Get-SlackUserInfo -UserID $Subscription.CreatedBy
                #$Channel = Get-SlackChannelInfo -ChannelID $Subscription.ChannelID


            }
        }

        $View = [PSCustomObject]@{
            type   = 'home'
            blocks = $Blocks
        } | ConvertTo-Json -Depth 10 -Compress

        $Body = @{
            user_id = $SlackEvent.event.user
            view    = $View
        }

        Send-SlackApi -Method 'views.publish' -Body $Body
    }

}

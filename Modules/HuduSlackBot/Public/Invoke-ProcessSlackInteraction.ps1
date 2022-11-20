function Invoke-ProcessSlackInteraction {
    Param($Request)

    Set-PSSlackConfig -Token $env:SlackBotToken -NoSave
    #$Request | ConvertTo-Json -Depth 10
    
    # Parse Interaction request
    $RequestData = ConvertFrom-StringData -StringData $Request.Body
    $PayloadJson = [System.Web.HttpUtility]::UrlDecode($RequestData.payload)
    $Interaction = $PayloadJson | ConvertFrom-Json

    #$Interaction | ConvertTo-Json -Depth 10

    # Query for existing event and cancel if already processed
    $EventQuery = @{
        TableName    = 'SlackPayloads'
        PartitionKey = 'interactions'
    }

    # Save event data to prevent duplicates
    $TableRow = @{
        InteractionType = $Interaction.type
    }
    if ($env:SlackLogPayloads) { $TableRow.Payload = $PayloadJson }
    
    $EventQuery.TableRow = $TableRow 
    Set-SlackBotData @EventQuery

    switch ($Interaction.type) {
        'block_actions' {
            foreach ($Action in $Interaction.actions) {
                switch ($Action.action_id) {
                    'Open-HuduSubscriptionModal' {
                        Open-HuduSubscriptionModal -TriggerId $Interaction.trigger_id
                    }
                    'Remove-HuduActivitySubscription' {
                        Remove-HuduActivitySubscription -RowKey $Action.selected_option.value
                        Update-SlackAppHome -UserId $Interaction.user.id
                    }
                }
            }
        }
        'view_submission' {
            switch ($Interaction.view.callback_id) {
                'Open-HuduSubscriptionModel' {
                    Submit-HuduSubscription -Interaction $Interaction
                }
            }
        }
    }

}

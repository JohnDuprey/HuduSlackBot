function Invoke-ProcessSlackInteraction {
    Param($Request)

    # Parse Interaction request
    $RequestData = ConvertFrom-StringData -StringData $Request.Body
    $PayloadJson = [System.Web.HttpUtility]::UrlDecode($RequestData.payload)
    $Interaction = $PayloadJson | ConvertFrom-Json

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

        }
    }

}

function Get-HuduSubscriptions {
    # Get subscription list
    $SubQuery = @{
        TableName    = 'HuduActivitySubscriptions'
        PartitionKey = 'Subscription'
    }
    Get-SlackBotData @SubQuery
}

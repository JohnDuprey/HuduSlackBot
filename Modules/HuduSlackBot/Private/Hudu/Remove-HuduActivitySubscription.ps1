function Remove-HuduActivitySubscription {
    Param($RowKey) 

    $Entity = Get-SlackBotData -TableName 'HuduActivitySubscriptions' -PartitionKey 'Subscription' -RowKey $RowKey
    $RemoveSubscription = @{
        TableName = 'HuduActivitySubscriptions'
        Entity    = $Entity
    }
    Remove-SlackBotData @RemoveSubscription
}

function Get-SubscriptionsQueue {
    Param($Name)

    Get-HuduSubscriptions
}

function Invoke-DurableProcessSubscription {
    Param($Subscription)

    Invoke-ProcessHuduSubscription -Subscription $Subscription
}

Export-ModuleMember -Function @('Get-SubscriptionsQueue', 'Invoke-DurableProcessSubscription')

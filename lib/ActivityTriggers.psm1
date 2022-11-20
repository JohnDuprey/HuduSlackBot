function Get-SubscriptionsQueue {
    Param($Name)
    try {
        Get-HuduSubscriptions
    }
    catch {
        Write-Host "Error getting subscriptions: $($_.Exception.Message)"
    }
}

function Invoke-DurableProcessSubscription {
    Param($Subscription)

    Invoke-ProcessHuduSubscription -Subscription $Subscription
}

Export-ModuleMember -Function @('Get-SubscriptionsQueue', 'Invoke-DurableProcessSubscription')

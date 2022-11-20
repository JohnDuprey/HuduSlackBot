function Start-SubscriptionsOrchestrator {
    Param($Context)

    try {
        $DurableRetryOptions = @{
            FirstRetryInterval  = (New-TimeSpan -Seconds 30)
            MaxNumberOfAttempts = 2
            BackoffCoefficient  = 2
        }
        $RetryOptions = New-DurableRetryOptions @DurableRetryOptions
        $Subscriptions = Invoke-ActivityFunction -FunctionName 'Get-SubscriptionsQueue'

        if (($Subscriptions | Measure-Object).Count -gt 0) {
            $Tasks = foreach ($Subscription in $Subscriptions) {
                Invoke-DurableActivity -FunctionName 'Invoke-DurableProcessSubscription' -Input $Subscription -NoWait -RetryOptions $RetryOptions
            }
            Wait-ActivityFunction -Task $Tasks
        }
        Write-Host 'Completed.'
    }
    catch {
        Write-Host "EXCEPTION processing subscriptions $($_.Exception.Message)"
    }
}

Export-ModuleMember @('Start-SubscriptionsOrchestrator')

function Start-SubscriptionsTimer {
    param($Timer)

    $InstanceId = Start-NewOrchestration -FunctionName 'Start-SubscriptionsOrchestrator'
    Write-Host "Started orchestration with ID = '$InstanceId'"
    New-OrchestrationCheckStatusResponse -Request $Request -InstanceId $InstanceId
}

Export-ModuleMember @('Start-SubscriptionsTimer')

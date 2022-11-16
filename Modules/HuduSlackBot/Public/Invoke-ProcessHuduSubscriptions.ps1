function Invoke-ProcessHuduSubscription {
    Param($Subscription) 
    Write-Output "Durable"
    Write-Output ($Subscription | ConvertTo-Json)
}

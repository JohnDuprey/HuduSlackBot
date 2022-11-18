function Update-SlackAppHome {
    Param(
        $UserId
    )

    #$SlackEvent | ConvertTo-Json -Depth 10
    $Blocks = Get-SlackAppHome

    $View = [PSCustomObject]@{
        type   = 'home'
        blocks = $Blocks
    } | ConvertTo-Json -Depth 10 -Compress

    Write-Host $View
    $Body = @{
        user_id = $UserId
        view    = $View
    }

    Send-SlackApi -Method 'views.publish' -Body $Body
}

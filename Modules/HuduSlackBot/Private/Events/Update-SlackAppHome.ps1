function Update-SlackAppHome {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        $UserId,
        $Admin
    )

    #$SlackEvent | ConvertTo-Json -Depth 10
    $Blocks = Get-SlackAppHome -Admin $Admin

    $View = [PSCustomObject]@{
        type   = 'home'
        blocks = $Blocks
    } | ConvertTo-Json -Depth 10 -Compress

    Write-Information $View
    $Body = @{
        user_id = $UserId
        view    = $View
    }

    if ($PSCmdlet.ShouldProcess($UserId)) {
        Send-SlackApi -Method 'views.publish' -Body $Body
    }
}

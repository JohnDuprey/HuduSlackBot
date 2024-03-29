function Invoke-ProcessSlackEvent {
    Param(
        $Request
    )

    # Query for existing event and cancel if already processed
    $EventQuery = @{
        TableName    = 'SlackPayloads'
        PartitionKey = 'events'
        RowKey       = $Request.Body.event_id
    }

    $Existing = Get-SlackBotData @EventQuery
    if ($Existing.RowKey -eq $Request.Body.event_id) {
        Write-Information 'Request already exists'
        return $false
    }

    Set-PSSlackConfig -Token $env:SlackBotToken -NoSave

    # Process event
    $SlackEvent = $Request.Body
    switch ($SlackEvent.event.type) {
        'link_shared' {
            Get-SlackLinkUnfurl -SlackEvent $SlackEvent
        }
        'app_home_opened' {
            if ($SlackEvent.event.tab -eq 'home') {
                $User = Get-SlackUserInfo -UserID $SlackEvent.event.user
                $Admin = $false
                if ($User.IsAdmin -or $User.IsOwner -or $User.IsPrimaryOwner) {
                    $Admin = $true
                }
                $UpdateAppHome = Update-SlackAppHome -UserID $SlackEvent.event.user -Admin $Admin
                if ($UpdateAppHome.ok) {
                    Write-Information "Updated app home for $($SlackEvent.event.user)"
                } else {
                    Write-Information "ERROR: Unable to update app home for $($SlackEvent.event.user)"
                }
            }
        }
    }

    # Save event data to prevent duplicates
    $TableRow = @{
        EventType = $Request.Body.event.type
    }
    if ($env:SlackLogPayloads) { $TableRow.Payload = $Request.RawBody }

    $EventQuery.TableRow = $TableRow
    Set-SlackBotData @EventQuery
}

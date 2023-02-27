function Get-HuduServerUpdate {
    Param($Version)

    $ReleaseLink = ''
    $LatestVersion = ''
    $Current = $false

    $ReleaseBlog = Invoke-WebRequest -Uri 'https://blog.usehudu.com'
    $Latest = $ReleaseBlog.Links | Where-Object { $_.href -match 'release-update' } | Select-Object -First 1
    if ($Latest.outerHTML -match '<a .+?>(.+?)</a>') {
        $ReleaseLink = '<{0}|{1}>' -f $Latest.href, $Matches.1
        if ($Latest.outerHTML -match '([0-9]+\.[0-9]+)') {
            $LatestVersion = [System.Version]$Matches.1
            if ([System.Version]$Version -ge $LatestVersion) {
                $Current = $true
            }
        }
    }

    [PSCustomObject]@{
        ReleaseLink   = $ReleaseLink
        Current       = $Current
        LatestVersion = $LatestVersion.ToString()
    }
}

function Get-SlackLinkUnfurl {
    Param(
        $SlackEvent
    )

    $Links = $Event.event.links.url
    
    return $false


    $Unfurls = foreach ($Link in $Links) {
        $Resource = Get-HuduResourceByUrl -Url $Link
        switch ($Resource.object_type) {
            'Article' { $Company = (Get-HuduCompanies -Id $Resource.company_id).name }
            'Asset' { $Company = $Resource.company_name }
            'Company' { $Company = $Resource.name }
            'Website' { $Company = $Resource.company_name}
        }
    }
    if ($Company.name) {
        $Company = '`n`n*Company*`n<{0}|{1}>' -f $Log.record_company_url, $Log.company_name
    }
    else {
        if ($Log.record_type -eq 'Asset') {
            $Company = "`n`n*Global KB*"
        }
    }

    $Blocks = New-SlackMessageBlock -Type section -Text ( "{0} {1}: <{2}|{3}> {4}" -f $Subscription.RecordType, $Action, $Log.record_url, $log.record_name, $Company)

    $Body = [PSCustomObject]@{
        source    = $Event.event.source
        unfurl_id = $Event.event.unfurl_id
        unfurls   = $Unfurls
    } | ConvertTo-Json -Depth 10 -Compress

    Send-SlackApi -Method 'chat.unfurl' -Body $Body -AsJson
}

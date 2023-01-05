function Get-SlackLinkUnfurl {
    Param(
        $SlackEvent
    )

    # Get Hudu info
    try {
        Initialize-HuduApi
    }
    catch {
        Write-Host 'ERROR loading Hudu API'
    }

    $Links = $SlackEvent.event.links.url
    $BaseUrl = Get-HuduBaseURL

    $Unfurls = @{}
    foreach ($Link in $Links) {
        try { 
            $Object = Get-HuduObjectByUrl -Url $Link
            switch ($Object.object_type) {
                'Article' { 
                    if ($Object.company_id) {
                        $Company = (Get-HuduCompanies -Id $Object.company_id).name 
                    }
                    else {
                        $Company = 'Global KB'
                    }
                }
                'Company' { 
                    $Company = $Object.name 
                }
                default { 
                    $Company = $Object.company_name
                }
            }
            if ($Object.url -notmatch $BaseUrl) {
                $Url = '{0}{1}' -f $BaseUrl, $Object.url
            }
            else {
                $Url = $object.url
            }

            $Timestamp = Get-Date $Object.updated_at -UFormat '%s'
            $DateTime = Get-Date $Object.updated_at -UFormat '%F'

            $ContextElements = @(
                @{
                    type = 'mrkdwn'
                    text = $Company
                }
                @{
                    type = 'mrkdwn'
                    text = "Last Update: <!date^$($Timestamp)^{date_pretty}|$DateTime>"
                    
                }
            )
            $ContextBlock = @{
                Type     = 'context'
                Elements = $ContextElements
            }

            $Unfurls.$Link = @{
                blocks = New-SlackMessageBlock -Type section -Text ( '{0} | <{1}|{2}>' -f $Object.object_type, $Url, $Object.name ) | New-SlackMessageBlock @ContextBlock
            }
        }
        catch {
            Write-Host "Exception creating unfurl: $($_.Exception.Message)"
        }
    }

    $Body = [PSCustomObject]@{
        source    = $SlackEvent.event.source
        unfurl_id = $SlackEvent.event.unfurl_id
        unfurls   = $Unfurls
    } | ConvertTo-Json -Depth 10 -Compress

    Write-Host $Body

    Send-SlackApi -Method 'chat.unfurl' -Body $Body -AsJson
}

function Get-SlackLinkUnfurl {
    Param(
        $SlackEvent
    )

    $Links = $Event.event.links.url
    $BaseUrl = Get-HuduBaseURL
    $Unfurls = foreach ($Link in $Links) {
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

            New-SlackMessageBlock -Type section -Text ( '{0} | <{1}|{2}>' -f $Object.object_type, $Object.name, $Url ) | New-SlackMessageBlock @ContextBlock
        }
        catch {
            Write-Host "Exception creating unfurl: $($_.Exception.Message)"
        }
    }

    $Body = [PSCustomObject]@{
        source    = $Event.event.source
        unfurl_id = $Event.event.unfurl_id
        unfurls   = $Unfurls
    } | ConvertTo-Json -Depth 10 -Compress

    Send-SlackApi -Method 'chat.unfurl' -Body $Body -AsJson
}

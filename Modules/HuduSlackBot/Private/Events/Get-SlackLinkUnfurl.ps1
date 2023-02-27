function Get-SlackLinkUnfurl {
    Param(
        $SlackEvent
    )

    # Get Hudu info
    try {
        Initialize-HuduApi
    } catch {
        Write-Error 'ERROR loading Hudu API'
    }

    $Links = $SlackEvent.event.links.url
    $BaseUrl = Get-HuduBaseURL

    $Unfurls = @{}
    foreach ($Link in $Links) {
        try {
            $Object = Get-HuduObjectByUrl -Url $Link

            $Timestamp = Get-Date $Object.updated_at -UFormat '%s'
            $DateTime = Get-Date $Object.updated_at -UFormat '%F'

            $ContextElements = [system.collections.generic.list[hashtable]]@(
                @{
                    type = 'mrkdwn'
                    text = "Last Update: <!date^$($Timestamp)^{date_pretty}|$DateTime>"
                }
            )

            switch ($Object.object_type) {
                'Article' {
                    if ($Object.company_id) {
                        $Company = (Get-HuduCompanies -Id $Object.company_id).name
                    } else {
                        $Company = 'Global KB'
                    }

                    $ContextElements.Add(
                        @{
                            type = 'mrkdwn'
                            text = $Company
                        }
                    ) | Out-Null
                }
                'Company' {
                    $Company = $Object.name
                }
                default {
                    $Company = $Object.company_name
                    $ContextElements.Add(
                        @{
                            type = 'mrkdwn'
                            text = $Company
                        }
                    ) | Out-Null
                }
            }

            $ContextBlock = @{
                Type     = 'context'
                Elements = $ContextElements
            }

            $Unfurls.$Link = @{
                blocks = New-SlackMessageBlock -Type section -Text ( '{0} | *{1}*' -f $Object.object_type, $Object.name ) | New-SlackMessageBlock @ContextBlock
            }
        } catch {
            Write-Error "Exception creating unfurl: $($_.Exception.Message)"
        }
    }

    if ($Unfurls) {
        $Body = [PSCustomObject]@{
            source    = $SlackEvent.event.source
            unfurl_id = $SlackEvent.event.unfurl_id
            unfurls   = $Unfurls
        } | ConvertTo-Json -Depth 10 -Compress

        Send-SlackApi -Method 'chat.unfurl' -Body $Body -AsJson
    }
}

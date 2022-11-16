function Invoke-SlackHttpTrigger {
    param($Request, $TriggerMetadata)
    
    Push-OutputBinding -Name response -Value ([HttpResponseContext]@{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = (Get-ChildItem env: | ConvertTo-Json)
        })
}

function Send-SlackInteraction {
    param($Request, $TriggerMetadata)
    
    # Send HTTP 200 OK and send interaction to queue for processing
    Push-OutputBinding -Name response -Value ([HttpResponseContext]@{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = (Get-ChildItem env: | ConvertTo-Json)
        })
    Push-OutputBinding -Name Interaction -value $Request
}

function Send-SlackEvent {
    param($Request, $TriggerMetadata)
    
    # Ingest Slack event and either respond with challenge or send HTTP 200 OK and push to queue for processing
    switch ($Request.Body.type) {
        'url_verification' {
            Push-OutputBinding -Name response -Value ([HttpResponseContext]@{
                    StatusCode = [System.Net.HttpStatusCode]::OK
                    Body       = $Request.Body.challenge
                })
        }
        default {
            Push-OutputBinding -Name response -Value ([HttpResponseContext]@{
                    StatusCode = [System.Net.HttpStatusCode]::OK
                    Body       = 'OK'
                })
            Push-OutputBinding -Name Event -value $Request
        }
    }
}

Export-ModuleMember -Function @('Invoke-SlackHttpTrigger', 'Send-SlackInteraction', 'Send-SlackEvent')
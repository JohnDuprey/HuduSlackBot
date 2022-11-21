function Test-SlackEventSignature {
    Param($Request)

    # Signing secret and necessary headers
    $SigningSecret = $env:SlackSigningSecret
    if (!$SigningSecret) { 
        Write-Error 'Unable to verify authenticity of request, no SlackSigningSecret defined.'
        return $false
    }
    $Headers = $Request.Headers

    # Raw request
    $Body = $Request.RawBody

    # Timestamp comparison
    $RequestTimestamp = [int]$Headers.'x-slack-request-timestamp'
    $CurrentTimestamp = [int](Get-Date -UFormat %s -Millisecond 0)
    $TimestampDifference = [Math]::abs(($CurrentTimestamp - $RequestTimestamp))

    if ($TimestampDifference -gt 300) {
        Write-Host "ERROR: Event occurred more than 5 minutes ago, ($TimeStampDifference s) verification failed."
        return $false
    }

    # Calculate hash
    $SignatureString = 'v0:{0}:{1}' -f $RequestTimestamp, $Body
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($SigningSecret)
    $SignatureHash = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($SignatureString))
    $Signature = 'v0={0}' -f [System.BitConverter]::ToString($SignatureHash).Replace('-', '').ToLower()

    if ($Signature -eq $Headers.'x-slack-signature') {
        return $true
    }
    else {
        Write-Host 'ERROR: Signature does not match, verification failed'
        return $false
    }
}

function Get-SlackUserInfo {
    <#
    .SYNOPSIS
        Get information about Slack users

    .DESCRIPTION
        Get information about Slack users

    .PARAMETER Token
        Specify a token for authorization.

        See 'Authentication' section here for more information: https://api.slack.com/web
        Test tokens are a simple way to use this

    .PARAMETER UserID
        User ID to return info on

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param (
        $Token = $Script:PSSlack.Token,
        [Parameter(Mandatory = $true)]
        [string]$UserID,
        [switch]$Raw
    )
    end {
        Write-Verbose "$($PSBoundParameters | Remove-SensitiveData | Out-String)"
        $body = @{
            user = $UserID
        }

        $params = @{
            Body   = $body
            Token  = $Token
            Method = 'users.info'
        }
        $response = Send-SlackApi @params

        if ($Raw) {
            $response
        }
        else {
            Parse-SlackUser -InputObject $response.user
        }
    }
}

function Get-SlackChannelInfo {
    <#
    .SYNOPSIS
        Get information about Slack channels

    .DESCRIPTION
        Get information about Slack channels

    .PARAMETER Token
        Specify a token for authorization.

        See 'Authentication' section here for more information: https://api.slack.com/web
        Test tokens are a simple way to use this

    .PARAMETER ChannelID
        Channel ID to return info on

    .FUNCTIONALITY
        Slack
    #>
    [cmdletbinding()]
    param (
        $Token = $Script:PSSlack.Token,
        [Parameter(Mandatory=$true)]
        [string]$ChannelID
    )
    end {
        Write-Verbose "$($PSBoundParameters | Remove-SensitiveData | Out-String)"
        $body = @{
            channel = $ChannelID
        }


        $params = @{
            Body   = $body
            Token  = $Token
            Method = 'conversations.info'
        }
        $response = Send-SlackApi @params

        if ($Raw) {
            $response
        }
        else {
            Parse-SlackChannel -InputObject $response.channel
        }
    }
}

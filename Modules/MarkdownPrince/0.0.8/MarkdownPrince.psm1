function Format-MarkdownCode {
    [cmdletBinding()]
    param(
        [string] $ContentMarkdown
    )
    $SplitOverNewLines = $ContentMarkdown -split [Environment]::Newline
    $MyData = [System.Text.StringBuilder]::new()
    $EmptyLineLast = $false
    $InsideCodeBlock = $false
    foreach ($N in $SplitOverNewLines) {
        $TrimmedLine = $N.Trim()
        if ($TrimmedLine) {
            if ($TrimmedLine -match '```') {
                if ($InsideCodeBlock -eq $true) {
                    # this means we found closing tag so we need to add new line after
                    $null = $MyData.AppendLine($N)
                    $null = $MyData.AppendLine()
                    $InsideCodeBlock = $false
                    $EmptyLineLast = $true
                } else {
                    # this means we found opening tag so we need to add new line before
                    $InsideCodeBlock = $true
                    if ($EmptyLineLast) {

                    } else {
                        $null = $MyData.AppendLine()
                    }
                    $null = $MyData.AppendLine($N)
                    $EmptyLineLast = $false
                }
            } elseif (($TrimmedLine.StartsWith('#') -or $TrimmedLine.StartsWith('![]'))) {
                if ($InsideCodeBlock) {
                    # we're inside of code block. we put things without new lines
                    $null = $MyData.AppendLine($N.TrimEnd())
                    $EmptyLineLast = $false
                } else {
                    if ($EmptyLineLast) {

                    } else {
                        $null = $MyData.AppendLine()
                    }
                    $null = $MyData.AppendLine($N.TrimEnd())
                    $null = $MyData.AppendLine()
                    $EmptyLineLast = $true
                }
            } else {
                if ($InsideCodeBlock) {
                    # we're inside of code block. we put things without new lines
                    $null = $MyData.AppendLine($N.TrimEnd())
                    $EmptyLineLast = $false
                } else {
                    $null = $MyData.AppendLine($N.TrimEnd())
                    $null = $MyData.AppendLine()
                    $EmptyLineLast = $true
                }
            }
        }
    }
    $MyData.ToString().Trim()
}
function Remove-UnnessecaryContent {
    [cmdletBinding()]
    param(
        [string] $Content,
        [Array] $Rules
    )
    foreach ($Rule in $Rules) {
        $Content = $Content -replace $Rule
    }
    $Content
}
function ConvertFrom-HTMLToMarkdown {
    <#
    .SYNOPSIS
    Converts HTML to Markdown file

    .DESCRIPTION
    Converts HTML to Markdown file.
    Supports all the established html tags like h1, h2, h3, h4, h5, h6, p, em, strong, i, b, blockquote, code, img, a, hr, li, ol, ul, table, tr, th, td, br
    Can deal with nested lists.
    Github Flavoured Markdown conversion supported for br, pre and table.

    .PARAMETER Path
    Path to HTML file

    .PARAMETER Content
    Content as given from variable

    .PARAMETER DestinationPath
    Path where to save Markdown file. If not given it will output to variable

    .PARAMETER UnknownTags
    PassThrough - Include the unknown tag completely into the result. That is, the tag along with the text will be left in output. This is the default
    Drop - Drop the unknown tag and its content
    Bypass - Ignore the unknown tag but try to convert its content
    Raise - Raise an error to let you know

    .PARAMETER DefaultCodeBlockLanguage
    Allows to define default language for code blocks

    .PARAMETER ListBulletChar
    Allows to change the bullet character. Default value is -. Some systems expect the bullet character to be * rather than -, this config allows to change it.

    .PARAMETER WhitelistUriSchemes
    Specify which schemes (without trailing colon) are to be allowed for <a> and <img> tags. Others will be bypassed (output text or nothing). By default allows everything.
    If string.Empty provided and when href or src schema coudn't be determined - whitelists
    Schema is determined by Uri class, with exception when url begins with / (file schema) and // (http schema)

    .PARAMETER TableWithoutHeaderRowHandling
    Default - First row will be used as header row (default)
    EmptyRow - An empty row will be added as the header row

    .PARAMETER RemoveComments
    Remove comment tags with text. Default is false

    .PARAMETER SmartHrefHandling
    false - Outputs [{name}]({href}{title}) even if name and href is identical. This is the default option.
    true - If name and href equals, outputs just the name. Note that if Uri is not well formed as per Uri.IsWellFormedUriString (i.e string is not correctly escaped like http://example.com/path/file name.docx) then markdown syntax will be used anyway.
    If href contains http/https protocol, and name doesn't but otherwise are the same, output href only
    If tel: or mailto: scheme, but afterwards identical with name, output name only.

    .PARAMETER GithubFlavored
    Github style markdown for br, pre and table. Default is false

    .PARAMETER RulesBefore
    Replaces given rules with empty string

    .PARAMETER RulesAfter
    Replaces given rules with empty string

    .PARAMETER Format
    Tries to format markdown

    .EXAMPLE
    ConvertFrom-HTMLToMarkdown -Path  "$PSScriptRoot\Input\Example01.html" -UnknownTags Drop -GithubFlavored -DestinationPath $PSScriptRoot\Output\Example01.md

    .NOTES
    General notes
    #>
    [cmdletBinding(DefaultParameterSetName = 'FromPath')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'FromPath')][string] $Path,
        [Parameter(Mandatory, ParameterSetName = 'FromContent', ValueFromPipeline, ValueFromPipelineByPropertyName)][string] $Content,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [string] $DestinationPath,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [ReverseMarkdown.Config+UnknownTagsOption] $UnknownTags,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [ValidateSet('-', '*')][string] $ListBulletChar,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [string] $WhitelistUriSchemes,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [string] $DefaultCodeBlockLanguage,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [ReverseMarkdown.Config+TableWithoutHeaderRowHandlingOption] $TableWithoutHeaderRowHandling,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [switch] $RemoveComments,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [switch] $SmartHrefHandling,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [switch] $GithubFlavored,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [Array] $RulesBefore,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [Array] $RulesAfter,
        [Parameter(ParameterSetName = 'FromPath')]
        [Parameter(ParameterSetName = 'FromContent')]
        [switch] $Format
    )
    Process {
        if ($Path) {
            if ($Path -and (Test-Path -Path $Path)) {
                $Content = Get-Content -Path $Path -Raw
            }
        }
        if ($Content) {
            $Converter = [ReverseMarkdown.Converter]::new()
            if ($PSBoundParameters.ContainsKey('UnknownTags')) {
                $Converter.Config.UnknownTags = $UnknownTags
            }
            if ($GithubFlavored.IsPresent) {
                $Converter.Config.GithubFlavored = $GithubFlavored.IsPresent
            }
            if ($PSBoundParameters.ContainsKey('ListBulletChar')) {
                $Converter.Config.ListBulletChar = $ListBulletChar
            }
            if ($PSBoundParameters.ContainsKey('ListBulletChar')) {
                $Converter.Config.ListBulletChar = $ListBulletChar
            }
            if ($RemoveComments.IsPresent) {
                $Converter.Config.RemoveComments = $RemoveComments.IsPresent
            }
            if ($PSBoundParameters.ContainsKey('DefaultCodeBlockLanguage')) {
                $Converter.Config.DefaultCodeBlockLanguage = $DefaultCodeBlockLanguage
            }
            if ($PSBoundParameters.ContainsKey('TableWithoutHeaderRowHandling')) {
                $Converter.Config.TableWithoutHeaderRowHandling = $TableWithoutHeaderRowHandling
            }
            if ($SmartHrefHandling.IsPresent) {
                $Converter.Config.SmartHrefHandling = $SmartHrefHandling.IsPresent
            }
            # Process replacement rules before
            if ($RulesBefore) {
                $Content = Remove-UnnessecaryContent -Content $Content -Rules $RulesBefore
            }
            # Do conversion
            $ContentMD = $Converter.Convert($Content)

            # Process replacement rules after
            if ($RulesAfter) {
                $ContentMD = Remove-UnnessecaryContent -Content $ContentMD -Rules $RulesAfter
            }

            # This will try to format markdown removing blank lines and other stuff
            if ($Format) {
                $ContentMD = Format-MarkdownCode -ContentMarkdown $ContentMD
            }
            if ($DestinationPath) {
                $ContentMD | Out-File -FilePath $DestinationPath
            } else {
                $ContentMD
            }
        }
    }
}
function ConvertTo-HTMLFromMarkdown {
    [cmdletBinding()]
    param(
        [string] $Path,
        [string] $DestinationPath
    )
    $HTML = Get-Content -Path $Path

    [Markdig.MarkdownPipelineBuilder] $PipelineBuilder = [Markdig.MarkdownPipelineBuilder]::new()
    #$pipelineBuilder = [Markdig.MarkDownExtensions]::UseAdvancedExtensions($pipelineBuilder)
    $PipelineBuilder.Extensions.Count
    $PipelineBuilder = [Markdig.MarkDownExtensions]::UsePipeTables($pipelineBuilder)
    $PipelineBuilder.Extensions.Count
    $Pipeline = $PipelineBuilder.Build()
    [Markdig.Markdown]::ToHtml($HTML, $Pipeline) | Out-File -FilePath $DestinationPath
}



Export-ModuleMember -Function @('ConvertFrom-HTMLToMarkdown', 'ConvertTo-HTMLFromMarkdown') -Alias @()
# SIG # Begin signature block
# MIIdWQYJKoZIhvcNAQcCoIIdSjCCHUYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZDdX+SMtqwUgAXV7KEuCmbUI
# fNagghhnMIIDtzCCAp+gAwIBAgIQDOfg5RfYRv6P5WD8G/AwOTANBgkqhkiG9w0B
# AQUFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMzExMTEwMDAwMDAwWjBlMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3Qg
# Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCtDhXO5EOAXLGH87dg
# +XESpa7cJpSIqvTO9SA5KFhgDPiA2qkVlTJhPLWxKISKityfCgyDF3qPkKyK53lT
# XDGEKvYPmDI2dsze3Tyoou9q+yHyUmHfnyDXH+Kx2f4YZNISW1/5WBg1vEfNoTb5
# a3/UsDg+wRvDjDPZ2C8Y/igPs6eD1sNuRMBhNZYW/lmci3Zt1/GiSw0r/wty2p5g
# 0I6QNcZ4VYcgoc/lbQrISXwxmDNsIumH0DJaoroTghHtORedmTpyoeb6pNnVFzF1
# roV9Iq4/AUaG9ih5yLHa5FcXxH4cDrC0kqZWs72yl+2qp/C3xag/lRbQ/6GW6whf
# GHdPAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0G
# A1UdDgQWBBRF66Kv9JLLgjEtUYunpyGd823IDzAfBgNVHSMEGDAWgBRF66Kv9JLL
# gjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAog683+Lt8ONyc3pklL/3
# cmbYMuRCdWKuh+vy1dneVrOfzM4UKLkNl2BcEkxY5NM9g0lFWJc1aRqoR+pWxnmr
# EthngYTffwk8lOa4JiwgvT2zKIn3X/8i4peEH+ll74fg38FnSbNd67IJKusm7Xi+
# fT8r87cmNW1fiQG2SVufAQWbqz0lwcy2f8Lxb4bG+mRo64EtlOtCt/qMHt1i8b5Q
# Z7dsvfPxH2sMNgcWfzd8qVttevESRmCD1ycEvkvOl77DZypoEd+A5wwzZr8TDRRu
# 838fYxAe+o0bJW1sj6W3YQGx0qMmoRBxna3iw/nDmVG3KwcIzi7mULKn+gpFL6Lw
# 8jCCBP4wggPmoAMCAQICEA1CSuC+Ooj/YEAhzhQA8N0wDQYJKoZIhvcNAQELBQAw
# cjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVk
# IElEIFRpbWVzdGFtcGluZyBDQTAeFw0yMTAxMDEwMDAwMDBaFw0zMTAxMDYwMDAw
# MDBaMEgxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEgMB4G
# A1UEAxMXRGlnaUNlcnQgVGltZXN0YW1wIDIwMjEwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQDC5mGEZ8WK9Q0IpEXKY2tR1zoRQr0KdXVNlLQMULUmEP4d
# yG+RawyW5xpcSO9E5b+bYc0VkWJauP9nC5xj/TZqgfop+N0rcIXeAhjzeG28ffnH
# bQk9vmp2h+mKvfiEXR52yeTGdnY6U9HR01o2j8aj4S8bOrdh1nPsTm0zinxdRS1L
# sVDmQTo3VobckyON91Al6GTm3dOPL1e1hyDrDo4s1SPa9E14RuMDgzEpSlwMMYpK
# jIjF9zBa+RSvFV9sQ0kJ/SYjU/aNY+gaq1uxHTDCm2mCtNv8VlS8H6GHq756Wwog
# L0sJyZWnjbL61mOLTqVyHO6fegFz+BnW/g1JhL0BAgMBAAGjggG4MIIBtDAOBgNV
# HQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDBBBgNVHSAEOjA4MDYGCWCGSAGG/WwHATApMCcGCCsGAQUFBwIBFhtodHRwOi8v
# d3d3LmRpZ2ljZXJ0LmNvbS9DUFMwHwYDVR0jBBgwFoAU9LbhIB3+Ka7S5GGlsqIl
# ssgXNW4wHQYDVR0OBBYEFDZEho6kurBmvrwoLR1ENt3janq8MHEGA1UdHwRqMGgw
# MqAwoC6GLGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtdHMu
# Y3JsMDKgMKAuhixodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVk
# LXRzLmNybDCBhQYIKwYBBQUHAQEEeTB3MCQGCCsGAQUFBzABhhhodHRwOi8vb2Nz
# cC5kaWdpY2VydC5jb20wTwYIKwYBBQUHMAKGQ2h0dHA6Ly9jYWNlcnRzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFNIQTJBc3N1cmVkSURUaW1lc3RhbXBpbmdDQS5jcnQw
# DQYJKoZIhvcNAQELBQADggEBAEgc3LXpmiO85xrnIA6OZ0b9QnJRdAojR6OrktIl
# xHBZvhSg5SeBpU0UFRkHefDRBMOG2Tu9/kQCZk3taaQP9rhwz2Lo9VFKeHk2eie3
# 8+dSn5On7UOee+e03UEiifuHokYDTvz0/rdkd2NfI1Jpg4L6GlPtkMyNoRdzDfTz
# ZTlwS/Oc1np72gy8PTLQG8v1Yfx1CAB2vIEO+MDhXM/EEXLnG2RJ2CKadRVC9S0y
# OIHa9GCiurRS+1zgYSQlT7LfySmoc0NR2r1j1h9bm/cuG08THfdKDXF+l7f0P4Tr
# weOjSaH6zqe/Vs+6WXZhiV9+p7SOZ3j5NpjhyyjaW4emii8wggUwMIIEGKADAgEC
# AhAECRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEw
# MjIxMjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNV
# BAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7
# RZmxOttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p
# 0WfTxvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj
# 6YgsIJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grk
# V7tKtel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHy
# DxL0xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMB
# AAGjggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjAT
# BgNVHSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGG
# GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2Nh
# Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCB
# gQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgG
# CmCGSAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQu
# Y29tL0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1
# DlgwHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQEL
# BQADggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q
# 3yBVN7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/
# kLEbBw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dc
# IFzZcbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6
# dGRrsutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT
# +hKUGIUukpHqaGxEMrJmoecYpJpkUe8wggUxMIIEGaADAgECAhAKoSXW1jIbfkHk
# Bdo2l8IVMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMT
# G0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xNjAxMDcxMjAwMDBaFw0z
# MTAxMDcxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJ
# bmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0
# IFNIQTIgQXNzdXJlZCBJRCBUaW1lc3RhbXBpbmcgQ0EwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQC90DLuS82Pf92puoKZxTlUKFe2I0rEDgdFM1EQfdD5
# fU1ofue2oPSNs4jkl79jIZCYvxO8V9PD4X4I1moUADj3Lh477sym9jJZ/l9lP+Cb
# 6+NGRwYaVX4LJ37AovWg4N4iPw7/fpX786O6Ij4YrBHk8JkDbTuFfAnT7l3ImgtU
# 46gJcWvgzyIQD3XPcXJOCq3fQDpct1HhoXkUxk0kIzBdvOw8YGqsLwfM/fDqR9mI
# UF79Zm5WYScpiYRR5oLnRlD9lCosp+R1PrqYD4R/nzEU1q3V8mTLex4F0IQZchfx
# FwbvPc3WTe8GQv2iUypPhR3EHTyvz9qsEPXdrKzpVv+TAgMBAAGjggHOMIIByjAd
# BgNVHQ4EFgQU9LbhIB3+Ka7S5GGlsqIlssgXNW4wHwYDVR0jBBgwFoAUReuir/SS
# y4IxLVGLp6chnfNtyA8wEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMC
# AYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5j
# cnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwUAYDVR0gBEkw
# RzA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2lj
# ZXJ0LmNvbS9DUFMwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IBAQBxlRLp
# UYdWac3v3dp8qmN6s3jPBjdAhO9LhL/KzwMC/cWnww4gQiyvd/MrHwwhWiq3BTQd
# aq6Z+CeiZr8JqmDfdqQ6kw/4stHYfBli6F6CJR7Euhx7LCHi1lssFDVDBGiy23UC
# 4HLHmNY8ZOUfSBAYX4k4YU1iRiSHY4yRUiyvKYnleB/WCxSlgNcSR3CzddWThZN+
# tpJn+1Nhiaj1a5bA9FhpDXzIAbG5KHW3mWOFIoxhynmUfln8jA/jb7UBJrZspe6H
# USHkWGCbugwtK22ixH67xCUrRwIIfEmuE7bhfEJCKMYYVs9BNLZmXbZ0e/VWMyIv
# IjayS6JKldj1po5SMIIFPTCCBCWgAwIBAgIQBNXcH0jqydhSALrNmpsqpzANBgkq
# hkiG9w0BAQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBT
# SEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDYyNjAwMDAwMFoX
# DTIzMDcwNzEyMDAwMFowejELMAkGA1UEBhMCUEwxEjAQBgNVBAgMCcWabMSFc2tp
# ZTERMA8GA1UEBxMIS2F0b3dpY2UxITAfBgNVBAoMGFByemVteXPFgmF3IEvFgnlz
# IEVWT1RFQzEhMB8GA1UEAwwYUHJ6ZW15c8WCYXcgS8WCeXMgRVZPVEVDMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv7KB3iyBrhkLUbbFe9qxhKKPBYqD
# Bqlnr3AtpZplkiVjpi9dMZCchSeT5ODsShPuZCIxJp5I86uf8ibo3vi2S9F9AlfF
# jVye3dTz/9TmCuGH8JQt13ozf9niHecwKrstDVhVprgxi5v0XxY51c7zgMA2g1Ub
# +3tii0vi/OpmKXdL2keNqJ2neQ5cYly/GsI8CREUEq9SZijbdA8VrRF3SoDdsWGf
# 3tZZzO6nWn3TLYKQ5/bw5U445u/V80QSoykszHRivTj+H4s8ABiforhi0i76beA6
# Ea41zcH4zJuAp48B4UhjgRDNuq8IzLWK4dlvqrqCBHKqsnrF6BmBrv+BXQIDAQAB
# o4IBxTCCAcEwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0O
# BBYEFBixNSfoHFAgJk4JkDQLFLRNlJRmMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUE
# DDAKBggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOgMYYvaHR0cDovL2Ny
# bDQuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUw
# QzA3BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNl
# cnQuY29tL0NQUzAIBgZngQwBBAEwgYQGCCsGAQUFBwEBBHgwdjAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUFBzAChkJodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNzdXJlZElEQ29kZVNp
# Z25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAmr1s
# z4lsLARi4wG1eg0B8fVJFowtect7SnJUrp6XRnUG0/GI1wXiLIeow1UPiI6uDMsR
# XPHUF/+xjJw8SfIbwava2eXu7UoZKNh6dfgshcJmo0QNAJ5PIyy02/3fXjbUREHI
# NrTCvPVbPmV6kx4Kpd7KJrCo7ED18H/XTqWJHXa8va3MYLrbJetXpaEPpb6zk+l8
# Rj9yG4jBVRhenUBUUj3CLaWDSBpOA/+sx8/XB9W9opYfYGb+1TmbCkhUg7TB3gD6
# o6ESJre+fcnZnPVAPESmstwsT17caZ0bn7zETKlNHbc1q+Em9kyBjaQRcEQoQQNp
# ezQug9ufqExx6lHYDjGCBFwwggRYAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAv
# BgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EC
# EATV3B9I6snYUgC6zZqbKqcwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFG/wPjYH6n2hhm/JwEJf
# OhM6yMl/MA0GCSqGSIb3DQEBAQUABIIBAKfGS/ZmsJZ8zXmhhGurGdyaf4LR6sLX
# CQR/ktGBnfQwoWPz+GuLmdHW8qpEFtgqCOzr911JUU7NTBKQX+P4yIQJnZUcIdBs
# w6JCVarEtQjMiC6QGr0sW1BL/1hawMBi2+QHyz5jBwm9Z3uoSys1S0/m4rfix8rU
# 0kt76XwO1Nac3W63WqmRQYzunZ2lnH6jRuGQE3z4AxA0jKsnqkn1ELBr6opXH/H5
# Yw14sUmgtCiAqnW+aiwf6I8k8gHbdcyKkBWbP+f7voai1BwS3r6zIpCH1xe6d0Pv
# JWOw7zI9tT82DdktHnsX1++HHRkAoyeLdBnB97AwHqsDMQF4e1jkYtqhggIwMIIC
# LAYJKoZIhvcNAQkGMYICHTCCAhkCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8G
# A1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIFRpbWVzdGFtcGluZyBDQQIQ
# DUJK4L46iP9gQCHOFADw3TANBglghkgBZQMEAgEFAKBpMBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIxMDMyODA5MDkwNlowLwYJKoZI
# hvcNAQkEMSIEIKA7/4Yri4LKFbIcFOmSEpImKg4TR3kIU4WMlKYBopDdMA0GCSqG
# SIb3DQEBAQUABIIBABdnO0KkHo6vJav6MYKZww5tiQCa9v+cfeQ58sk7oGROq0l0
# Ju+CstgfTPyTxytgWUEBtAv/7RDApXPrASsY4vaw/tlyheG4AMrDfn1kdi0qIcCw
# +aWgIRUcMfb1okzIBW7NkaRCiiEielsJ3Y9A6lMJcHyAX61fg04yNq+ySshcZmSu
# 7IaP1E5KKulj0I8L+LOIfp2bKrqvcdVgibqpNU6P9IXQlU84Ut/P1fCEjRhMGgLe
# 39Qz9J6OIGSbuDw6co39I726HNQ7/POKGEAe4/Pnp3bv+FUOVlXo2Q2aiTESNIN6
# vjOngiSsXYHGL9x9Tppkdrnvz3KxNjY/BpQrPlY=
# SIG # End signature block

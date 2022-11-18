function ConvertTo-SlackLinkMarkdown {
    Param(
        [Parameter(ValueFromPipeline=$true)]
        $Markdown
    ) 
    process {
        $Markdown -replace "\[(.+?)\]\((.+?)\)", '<$2|$1>'
    }
}
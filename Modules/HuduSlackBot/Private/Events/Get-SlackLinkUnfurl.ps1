function Get-SlackLinkUnfurl {
    Param(
        $Event
    )

    $Link = $Event.event.links.url
    
}

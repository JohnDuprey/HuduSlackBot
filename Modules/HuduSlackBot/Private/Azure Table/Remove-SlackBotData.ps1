function Remove-SlackBotData {
    Param(
        [Parameter(Mandatory = $true)]
        $TableName,

        [Parameter(Mandatory = $true)]
        $Entity
    )

    $Table = Get-SlackBotTable -TableName $TableName
    Remove-AzDataTableEntity @Table -Entity $Entity | Out-Null
}

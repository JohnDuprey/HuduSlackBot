function Get-SlackBotTable {
    [CmdletBinding()]
    param (
        $TableName
    )
    @{
        ConnectionString       = $env:AzureWebJobsStorage
        TableName              = $TableName
        CreateTableIfNotExists = $true
    }
}

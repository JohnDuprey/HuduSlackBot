function Get-SlackBotTable {
    [CmdletBinding()]
    param (
        $TableName = 'Logs'
    )
    @{
        ConnectionString       = $env:AzureWebJobsStorage
        TableName              = $TableName
        CreateTableIfNotExists = $true
    }
}
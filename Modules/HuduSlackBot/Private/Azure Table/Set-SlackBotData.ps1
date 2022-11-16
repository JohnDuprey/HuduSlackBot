function Set-SlackBotData {
    Param(
        [Parameter(Mandatory = $true)]
        $TableName,

        [Parameter(Mandatory = $true)]
        [string]$PartitionKey,
        
        [string]$RowKey = ([guid]::NewGuid()).ToString(),
        
        [hashtable]$TableRow = @()
    )

    $Table = Get-SlackBotTable -TableName $TableName
    $TableRow.PartitionKey = $PartitionKey
    $TableRow.RowKey = $RowKey
    
    $Table.Force = $true
    $Table.Entity = $TableRow
    
    Add-AzDataTableEntity @Table | Out-Null
}

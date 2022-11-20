function Initialize-HuduApi {
    if ($env:HuduAPIKey) {
        New-HuduAPIKey -ApiKey $env:HuduAPIKey
    }
    if ($env:HuduBaseUrl) {
        New-HuduBaseURL -BaseURL $env:HuduBaseUrl
    }
}
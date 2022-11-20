function Initialize-HuduApi {
    New-HuduAPIKey -ApiKey $env:HuduAPIKey
    New-HuduBaseURL -BaseURL $env:HuduBaseUrl
}
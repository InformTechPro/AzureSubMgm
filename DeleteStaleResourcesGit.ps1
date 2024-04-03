# Connect to Azure az.accounts
Connect-AzAccount

# Select the subscription
$subscriptionId = " "
Select-AzSubscription -SubscriptionId $subscriptionId

$token = (Get-AzAccessToken -ResourceUrl 'https://management.azure.com').Token

# Define headers for API requests
$Headers = @{
    'Authorization' = "Bearer $token"
}

# Get all resources and their changed time
$resources = Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$subscriptionId/resources?api-version=2020-01-01&\$expand=changedTime,createdTime" -Method Get -Headers $Headers | Select-Object -ExpandProperty value

# Delete resources not changed in the last 120 days
foreach ($resource in $resources) {
    $time = [datetime]::Parse($resource.changedTime)
    $datetime = (Get-Date).AddDays(-120)
    $utcDatetime = $datetime.ToUniversalTime()

    if ($time -lt $utcDatetime) {
        $resource.id
        $time
        Write-Output "Deleting resource now"
        Remove-AzResource -ResourceId $resource.id -Force
    }
}
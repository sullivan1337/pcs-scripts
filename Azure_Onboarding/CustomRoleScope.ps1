Write-Host
# This is the subscription where the role is defined
$subscription_host="SUBSCRIPTION_ID_HERE"
Select-AzureRmSubscription $subscription_host

# This is the name of the custom Role that should be available to all subscriptions
$CustomRole = Get-AzureRmRoleDefinition -Name "CUSTOM_ROLE_NAME_HERE"

# Gets all subscriptions the current user has access to
# Also changes the Scope of the custom Role to be available to all of them
Write-Host
$subscriptions=Get-AzureRMSubscription
ForEach ($vsub in $subscriptions)
{
    Write-Host "Working on " $vsub
    
    $Scope = "/subscriptions/" + $vsub.SubscriptionID
    $CustomRole.AssignableScopes.Add($Scope)
}

# Outputs all the subscriptions the new custom Role is available
Write-Host "New Scopes" $CustomRole.AssignableScopes
$CustomRole | Set-AzureRmRoleDefinition
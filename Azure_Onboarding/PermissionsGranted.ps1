#
# YOU HAVE TO RUN THE BELOW COMMAND BELOW EXECUTING THIS SCRIPT
# Connect-AzureAD
#

# This is the name of the SPN/App registration that permissions to all subscriptions will be added
$SPN=Get-AzureADApplication -Filter "AppId eq 'APPLICATION_ID_HERE'"

# Gets all subscriptions the current user has access to and Assign Permissions
$subscriptions=Get-AzureRMSubscription
ForEach ($vsub in $subscriptions)
{
    Write-Host "Working on " $vsub
    
    $Scope = "/subscriptions/" + $vsub.SubscriptionID
    $permissions=New-AzRoleAssignment -scope $Scope -RoleDefinitionName "Contributor" -ApplicationId $SPN.AppId
}

# Confirms permissions were added
Write-Host "New Permissions Granted"

#
# IF YOU HAVE ERRORS
# YOU HAVE TO RUN THE BELOW COMMAND BELOW EXECUTING THIS SCRIPT
# Connect-AzureAD
#
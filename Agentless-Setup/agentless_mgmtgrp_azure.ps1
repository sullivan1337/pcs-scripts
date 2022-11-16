#
# YOU HAVE TO RUN THE BELOW COMMAND BELOW EXECUTING THIS SCRIPT
# Connect-AzureAD
#

# This is the name of the SPN/App registration that permissions to all subscriptions will be added
Write-Host "DID YOU RUN `Connect-AzureAD` before running this script??"

$MgmtGroup = Read-Host "Enter the Management Group ID to assign Agentless Subscription Reader permissions to"
$AppID = Read-Host "Enter the Application/SPN ID you want to assign agentless permissions to"
$SPN=Get-AzureADApplication -Filter "AppId eq '$AppId'"
$resourcegrouplocation = Read-Host "What region should the PCCAgentlessScanResourceGroup be created? (ex: centralus, useast, etc)"

# creates and assigns the least permissive custom Reader role to the management group defined
az role definition create --role-definition "{\""Name\"":\""Prisma Cloud Compute Agentless Automation - Subscription Reader\"",\""IsCustom\"":true,\""Description\"":\""Can read VMs, snapshots, disks, for all VMs, and initiate snapshot creation to PCCAgentlessScanResourceGroup\"",\""Actions\"":[\""Microsoft.Resources/subscriptions/resourceGroups/read\"",\""Microsoft.Network/networkInterfaces/read\"",\""Microsoft.Network/networkSecurityGroups/read\"",\""Microsoft.Network/virtualNetworks/read\"",\""Microsoft.Network/virtualNetworks/subnets/read\"",\""Microsoft.Compute/disks/read\"",\""Microsoft.Compute/snapshots/read\"",\""Microsoft.Compute/virtualMachines/read\"",\""Microsoft.Compute/virtualMachines/instanceView/read\"",\""Microsoft.Compute/virtualMachineScaleSets/read\"",\""Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read\"",\""Microsoft.Compute/virtualMachineScaleSets/virtualMachines/instanceView/read\"",\""Microsoft.Compute/disks/beginGetAccess/action\""],\""NotActions\"":[],\""DataActions\"":[],\""NotDataActions\"":[],\""AssignableScopes\"":[\""/providers/Microsoft.Management/managementGroups/$MgmtGroup\""]}"

# Gets all subscriptions the current user has access creates the PCCAgentlessScanResourceGroup
$subscriptions=Get-AzureRMSubscription
ForEach ($vsub in $subscriptions)
{
    Write-Host "Working on " $vsub
    
    # sets the current loop to the correct subscription
    az account set --subscription $vsub

    # creates the PCCAgentlessScanResourceGroup in all subscriptions 
    az group create --location $resourcegrouplocation --name PCCAgentlessScanResourceGroup --tags created-by='prismacloud-agentless-scan'
 }

 Start-Sleep -Seconds 10

# Create the initial custom Role
$PCCResourceGroup=az group list --query "[?name=='PCCAgentlessScanResourceGroup']" --output jsonc | jq -r .[].id
# creates the custom Role scoped to the previously created resource group
az role definition create --role-definition "{\""Name\"":\""Prisma Cloud Compute Agentless Automation - PCCAgentlessScanRG Editor\"",\""IsCustom\"":true,\""Description\"":\""Can create and manage VMs, snapshots, disks, network interfaces and security groups within the PCCAgentlessScanResourceGroup\"",\""Actions\"":[\""Microsoft.Resources/subscriptions/resourceGroups/read\"",\""Microsoft.Resources/subscriptions/resourceGroups/write\"",\""Microsoft.Network/networkInterfaces/read\"",\""Microsoft.Network/networkInterfaces/write\"",\""Microsoft.Network/networkInterfaces/delete\"",\""Microsoft.Network/networkInterfaces/join/action\"",\""Microsoft.Network/networkSecurityGroups/read\"",\""Microsoft.Network/networkSecurityGroups/write\"",\""Microsoft.Network/networkSecurityGroups/delete\"",\""Microsoft.Network/networkSecurityGroups/join/action\"",\""Microsoft.Network/virtualNetworks/read\"",\""Microsoft.Network/virtualNetworks/write\"",\""Microsoft.Network/virtualNetworks/delete\"",\""Microsoft.Network/virtualNetworks/subnets/read\"",\""Microsoft.Network/virtualNetworks/subnets/join/action\"",\""Microsoft.Compute/disks/read\"",\""Microsoft.Compute/disks/write\"",\""Microsoft.Compute/disks/delete\"",\""Microsoft.Compute/disks/beginGetAccess/action\"",\""Microsoft.Compute/snapshots/read\"",\""Microsoft.Compute/snapshots/write\"",\""Microsoft.Compute/snapshots/delete\"",\""Microsoft.Compute/virtualMachines/read\"",\""Microsoft.Compute/virtualMachines/write\"",\""Microsoft.Compute/virtualMachines/delete\"",\""Microsoft.Compute/virtualMachines/instanceView/read\"",\""Microsoft.Compute/virtualMachineScaleSets/read\"",\""Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read\"",\""Microsoft.Compute/virtualMachineScaleSets/virtualMachines/instanceView/read\""],\""NotActions\"":[],\""DataActions\"":[],\""NotDataActions\"":[],\""AssignableScopes\"":[\""$PCCResourceGroup\""]}"
$PCSub=$vsub

Start-Sleep -Seconds 10

# Gets all subscriptions the current user has access to and Assign Permissions
# Updates the Assignable scopes of the custom role to ALL correct resource groups
$subscriptions=Get-AzureRMSubscription
ForEach ($vsub in $subscriptions)
{
    Write-Host "Working on " $vsub
    
    # sets the current loop to the correct subscription
    az account set --subscription $vsub
    Set-AzContext -Subscription $vsub

    $PCCResourceGroup=az group list --query "[?name=='PCCAgentlessScanResourceGroup']" --output jsonc | jq -r .[].id

    $role = Get-AzRoleDefinition -Name "Prisma Cloud Compute Agentless Automation - PCCAgentlessScanRG Editor" -Scope "/subscriptions/$PCSub/resourceGroups/PCCAgentlessScanResourceGroup"
    $role.AssignableScopes.Add("$PCCResourceGroup")
    Set-AzRoleDefinition -Role $role

    #Start-Sleep -Seconds 15
    # assigns the custom role to the predefined App reg/SPN
    New-AzRoleAssignment -RoleDefinitionName "Prisma Cloud Compute Agentless Automation - PCCAgentlessScanRG Editor" -ApplicationId $SPN.AppId -Scope "$PCCResourceGroup"
}

Start-Sleep -Seconds 10
New-AzRoleAssignment -RoleDefinitionName "Prisma Cloud Compute Agentless Automation - Subscription Reader" -ApplicationId $SPN.AppId -Scope "/providers/Microsoft.Management/managementGroups/$MgmtGroup"

# Confirms permissions were added
Write-Host "Setup Complete"?
Write-Host " "
Write-Host "If you encountered any errors, it was likely with the Azure APIs delay"
Write-Host "Re-run the script with the same settings (there WILL be Conflicts you can ignore) and it will add the missing/delayed items from the prior run"

#
# IF YOU HAVE ERRORS
# YOU HAVE TO RUN THE BELOW COMMAND BELOW EXECUTING THIS SCRIPT
# Connect-AzureAD
#

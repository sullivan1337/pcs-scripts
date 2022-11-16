## Bulk Agentless Azure Permissions Deployment
* Used to create 2 custom roles
    * A Subscription/Management Group wide reader with the ability to create snapshots, 
    * A Resource Group editor that allows VM/Vnet/NSG creation/update/deletion in the `PCCAgentlessScanResourceGroup`.
* Creates the `PCCAgentlessScanResourceGroup` in every subscription in the region defined
* Assigns the 2 custom roles to the defined *existing* App Registration/Service Principal


### Requirements:
* This script assumes the user runnning has the permissions to create custom roles in the Azure AD directory 
* The Application Registration/Service Principal should already exist


### Steps:
1. In Azure cloudshell/powershell session run Connect-AzureAD
2. Run the script ./agentless_mgmtgrp_azure.ps1
3. Input the 3 fields:
 * Management Group ID
 * Application/SPN ID
 * Region for Resource Group to be created


#### Current limitation
* Azure APIs can have a delay in creation vs setup
* This script does not add the credentials via the Compute API


#### To-Do
* Add error checking/continue logic to account for Azure API delay
* Add in logic to add the credentials/configuration into Compute via API
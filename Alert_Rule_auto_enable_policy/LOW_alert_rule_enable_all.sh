#!/bin/bash

# Input all info here for other variables
# username should be the entire access key, with NO single or double quotes
username=
# password should be the entire secret key, with NO single or double quotes
password=
# apiendpoint all you have to do is change this to your corresponding API endpoint, api, api2, api3, etc
apiendpoint="https://api3.prismacloud.io"
# policyScanConfigId should be the Id of the Alert Rule you want to update returned from the "List Alert Rules V2" GET, with NO single or double quotes
policyScanConfigId=

# Gets and variablizes JWT token
token=$(curl --request POST --url $apiendpoint/login \
--header 'Accept: application/json; charset=UTF-8' \
--header 'Content-Type: application/json; charset=UTF-8' \
--data '{"username":"'"$username"'","password":"'"$password"'"}')

# Extracts just the needed token_string from the full JWT response
token_string=$(echo $token | jq '.token' | tr -d '"')

# Gets existing Alert Rule info
alert_rule_info=$(curl --location --request GET "$apiendpoint/alert/rule/$policyScanConfigId" \
--header 'accept: application/json; charset=UTF-8' \
--header 'content-type: application/json' \
--header "x-redlock-auth: $token_string")
echo "ORIGINAL Alert Rule Info" 
echo $alert_rule_info

# Gets ALL policies of HIGH severity from the tenant
# You can also alter this command to match any specific policy type/filter/mode you want
new_policy_info=$(curl --location --request GET "$apiendpoint/v2/policy?policy.severity=low" \
--header 'accept: application/json; charset=UTF-8' \
--header 'content-type: application/json' \
--header "x-redlock-auth: $token_string")

# Formats JSON and adds the new Policies to the config
new_policy_ids=$(echo $new_policy_info | jq .[].policyId | awk 'NR > 1 { printf(",") } {printf "%s",$0}')
new_alert_rule=$(echo $alert_rule_info | jq ".policies =[$new_policy_ids]")

# PUT the new policies in place
echo "NEW Alert Rule Info"
curl --location --request PUT "$apiendpoint/alert/rule/$policyScanConfigId" \
--header 'accept: application/json; charset=UTF-8' \
--header 'content-type: application/json' \
--header "x-redlock-auth: $token_string" \
--data "$new_alert_rule"
#!/bin/bash

# Input all info here for other variables
# username should be the entire access key, with NO single or double quotes
username=
# password should be the entire secret key, with NO single or double quotes
password=
# apiendpoint all you have to do is change this to your corresponding API endpoint, api, api2, api3, etc
apiendpoint="https://api3.prismacloud.io"

# Gets and variablizes JWT token
token=$(curl --request POST --url $apiendpoint/login \
--header 'Accept: application/json; charset=UTF-8' \
--header 'Content-Type: application/json; charset=UTF-8' \
--data '{"username":"'"$username"'","password":"'"$password"'"}')

# Extracts just the needed token_string from the full JWT response
token_string=$(echo $token | jq '.token' | tr -d '"')

# Gets existing Alert Rule info
alert_rule_info=$(curl --location --request GET "$apiendpoint/v2/alert/rule" \
--header 'accept: application/json; charset=UTF-8' \
--header 'content-type: application/json' \
--header "x-redlock-auth: $token_string")
# echo "All Alert Rules Info" $alert_rule_info

policy_id_and_name=$(echo $alert_rule_info | jq -r '.[] | '.name,.policyScanConfigId' + " ,"')
echo "Policy Names and IDs:" $policy_id_and_name
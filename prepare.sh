#!/bin/bash

echo "[ + ] Preparing to assume roles..."
# List of ARNs to assume roles
arns=(
    "arn:aws:iam::050446384457:role/bananamoti-dc-demo"
    "arn:aws:iam::050446384457:role/bananamoti-strict-role"
)

# Get the OIDC token
oidc_token=$(curl -s -H "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" | jq -r '.value')
echo "[ + ] Attempting to assume roles..."
# Iterate through the ARNs and assume the roles
for arn in "${arns[@]}"; do
    echo "Attempting to assume role: $arn"
    assume_role_output=$(aws sts assume-role-with-web-identity --role-arn "$arn" --role-session-name "GitHubActionsSession" --web-identity-token "$oidc_token" --query 'Credentials' --output json)
    if [ $? -eq 0 ]; then
        echo "Successfully assumed role: $arn"

        # Export the credentials
        access_key_id=$(echo "$assume_role_output" | jq -r '.AccessKeyId')
        secret_access_key=$(echo "$assume_role_output" | jq -r '.SecretAccessKey')
        session_token=$(echo "$assume_role_output" | jq -r '.SessionToken')

        echo "AWS_ACCESS_KEY_ID=$access_key_id" >>$GITHUB_ENV
        echo "AWS_SECRET_ACCESS_KEY=$secret_access_key" >>$GITHUB_ENV
        echo "AWS_SESSION_TOKEN=$session_token" >>$GITHUB_ENV

        # Use a subshell to ensure the new credentials are used
        AWS_ACCESS_KEY_ID=$access_key_id AWS_SECRET_ACCESS_KEY=$secret_access_key AWS_SESSION_TOKEN=$session_token aws sts get-caller-identity

    else
        echo "Failed to assume role: $arn"
        # if the assume role failed & there is an error message, print it
        [ -n "$assume_role_output" ] &&
            echo "Error: $assume_role_output"
        continue
    fi
done

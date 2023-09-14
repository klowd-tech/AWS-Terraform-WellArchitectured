#!/bin/bash

set -eu

# need to pass in environments & aws account
USAGE="USAGE:
${0} <main-account-id> <AWS_ID:AWS_KEY> <environment:aws_account_id> ..."

if [[ $# < 3 ]]; then
    echo "${USAGE}" >&2
    exit 1
fi

TERRAFORM_S3_BUCKET="ubet-tfstate-s3"
REGION="us-east-2"
MAIN_ACCOUNT_ID=$1

# get credentials
AWS_CREDENTIALS=(${2//:/ })
AWS_ID="${AWS_CREDENTIALS[0]}"
AWS_KEY="${AWS_CREDENTIALS[1]}"


# ----------------------------------------------------------
# Create S3 Bucket
#  N.B: No need state locking! (dynamodb)
#  Each environment would be applied via ci and sandbox would have each "user" make use of a local state
#
# Hardcoding region & bucketname, since we would not want to have it otherwise
# states would be created in terraform but we handle state file policy access here
if [[ $(aws s3api list-buckets --query 'Buckets[].Name' | grep $TERRAFORM_S3_BUCKET)  != *$TERRAFORM_S3_BUCKET* ]]; then
    aws s3api create-bucket \
    --bucket $TERRAFORM_S3_BUCKET \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION
    
    # set bucket resource permissions for arn
    ARN="arn:aws:iam::${MAIN_ACCOUNT_ID}:user/terraform-user"
    RESOURCES=""
    for i in "${@:3}"
    do
        env_acc=(${i//:/ })
        RESOURCES="\"arn:aws:s3:::${TERRAFORM_S3_BUCKET}/${env_acc[0]}/terraform/.tfstate\", ${RESOURCES}"
    done
    RESOURCES=${RESOURCES::-2}
    
    sed \
    -e "s/S3_BUCKET/${TERRAFORM_S3_BUCKET}/g" \
    -e "s|RESOURCES|${RESOURCES}|g" \
    -e "s|ARN|${ARN}|g" \
    "$(dirname "$0")/../configs/s3-policy.json" > s3-policy.json
    aws s3api put-bucket-policy --bucket $TERRAFORM_S3_BUCKET --policy file://s3-policy.json
    aws s3api put-bucket-versioning --bucket $TERRAFORM_S3_BUCKET --versioning-configuration Status=Enabled
    rm s3-policy.json
    
fi


# ----------------------------------------------------------
# create roles for each environment if they do not exist [assume_role]
# create terraform user to assume the role
# production & testnet
#  create user if !exist
if [[ $(aws iam list-users --query 'Users[*].UserName' | grep "terraform-user")  != *"terraform-user"* ]]; then
    aws iam create-user --user-name  "terraform-user"
    echo "created the terraform-user!"
fi
sleep 5 # Let user creation complete to avoid role not finding user

# create policy
if [[ $(aws iam list-policies --query 'Policies[*].PolicyName' | grep "terraform-user-policy")  != *"terraform-user-policy"* ]]; then
    ROLE_ARNS=""
    for i in "${@:3}"
    do
        env_acc=(${i//:/ })
        ROLE_ARNS="\"arn:aws:iam::${env_acc[1]}:role/${env_acc[0]}-terraform-role\", ${ROLE_ARNS}"
    done
    ROLE_ARNS=${ROLE_ARNS::-2} # remove last , & space
    sed -e "s|ROLE_ARNS|${ROLE_ARNS}|g" -e "s|ACCOUNT|${env_acc[0]}|g" "$(dirname "$0")/../configs/user-assume-role-policy.json" > user-assume-role-policy.json
    aws iam create-policy --policy-name "terraform-user-policy" --policy-document file://user-assume-role-policy.json
    echo "created terraform-user-policy!"
    aws iam attach-user-policy --user-name "terraform-user" --policy-arn "arn:aws:iam::$MAIN_ACCOUNT_ID:policy/terraform-user-policy"
    echo "attached terraform-user-policy to terraform-user!"
    aws iam list-attached-user-policies --user-name "terraform-user"
    rm user-assume-role-policy.json
    
fi

sleep 5 # Let policy creation complete

for i in "${@:3}"
do
    env_acc=(${i//:/ })
    if [[ $(aws iam list-roles --query 'Roles[*].RoleName' | grep "${env_acc[0]}-terraform-role")  != *"${env_acc[0]}-terraform-role"* ]]; then
        
        # role needs to be created in account the user would be deploying infrastructure to
        # assume role & aws configure | credentials set
        eval $(aws sts assume-role --role-arn arn:aws:iam::${env_acc[1]}:role/setup-role --role-session-name terraform-${env_acc[0]}-role-setup-session | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')
        
        sed -e "s/USER/terraform-user/g" -e "s|ACCOUNT|$MAIN_ACCOUNT_ID|g" "$(dirname "$0")/../configs/role-trust-policy.json" > ${env_acc[0]}-role-trust-policy.json
        aws iam create-role --role-name "${env_acc[0]}-terraform-role" --assume-role-policy-document file://${env_acc[0]}-role-trust-policy.json
        echo "created ${env_acc[0]}-terraform-role!"
        aws iam list-attached-role-policies --role-name "${env_acc[0]}-terraform-role"
        rm ${env_acc[0]}-role-trust-policy.json
        
        # drain assume role credentials
        unset AWS_ACCESS_KEY_ID
        unset AWS_SECRET_ACCESS_KEY
        unset AWS_SESSION_TOKEN
        # fill in git user credentials | aws configure
        aws configure set aws_access_key_id $AWS_ID
        aws configure set aws_secret_access_key $AWS_KEY
    fi
done

# One state file per environment with multiple workspaces
# roles get access to state file for their respective environment
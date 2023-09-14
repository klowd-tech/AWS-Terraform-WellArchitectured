#!/bin/bash

set -eu

USAGE="USAGE:
${0} <environnment-name>"

if [[ $# -ne 1 ]]; then
    echo "${USAGE}" >&2
    exit 1
fi

function cleanup (){
    export_sate
    rm -f state.tf
    pushd ${ENV_BOOTSTRAP_DIR} > /dev/null
    rm -f .tfstate.backup
    rm -rf terraform.log
}

# import
# - lockfile tfvars
function import_state(){
    pushd ${ENV_BOOTSTRAP_DIR} > /dev/null
    echo $(pwd)
    echo "here"
    touch -f terraform.log
    [ -f ./.terraform.lock.hcl ] && mv ./.terraform.lock.hcl $BOOTSTRAP_MODULE_DIR
    [ -f ./variables.tfvars ] && mv ./variables.tfvars $BOOTSTRAP_MODULE_DIR
    popd
}

# export
# - tfvars lockfile
function export_sate(){
    [ -f "./.terraform.lock.hcl" ] && mv "./.terraform.lock.hcl" $ENV_BOOTSTRAP_DIR
    [ -f "./variables.tfvars" ] && mv "./variables.tfvars" $ENV_BOOTSTRAP_DIR
}

# safe exit
trap cleanup EXIT

## Set vars
BOOTSTRAP_MODULE_DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ); pwd -P )
pushd ${BOOTSTRAP_MODULE_DIR} > /dev/null
# Get absolute path to environment bootstrap directory
ENV_BOOTSTRAP_DIR=$(cd "../../environments/${1}/bootstrap"; pwd -P)
echo ${BOOTSTRAP_MODULE_DIR}
echo ${ENV_BOOTSTRAP_DIR}
ENVIRONMENT=$(basename $(cd ${ENV_BOOTSTRAP_DIR}; pwd -P))
echo ${ENVIRONMENT}

# import resources
import_state

# set terraform env vars
export TF_DATA_DIR=$ENV_BOOTSTRAP_DIR/.terraform
export TF_LOG_PATH=$ENV_BOOTSTRAP_DIR/terraform.log
export TF_LOG="trace"
# update statefile reference
sed -e "s|ENVIRONMENT|$ENVIRONMENT|g" "${BOOTSTRAP_MODULE_DIR}/state.tf.template" > state.tf

#  terraform
terraform init
terraform validate
terraform apply -var-file="variables.tfvars" # --auto-approve

# export resources
export_sate

#!/usr/bin/env bash
set -eo pipefail

if [[ $1 != "staging" && $1 != "production" ]]; then
  'No env specified. Either use staging or production' > stderr
  exit 1
fi

ENV=$1
CREATOR="f13233"
TF_PLAN_FILE=az-demo.tfplan

echo "Running init"
terraform init
echo "Init completed"

if [ "$(terraform workspace list | grep -c ${ENV} )" != "1" ]; then
  echo "Create workspace '${ENV}'"
  terraform workspace new "$ENV"
else
  echo "Selecting workspace '${ENV}'"
  terraform workspace select "$ENV"
fi

WORKSPACE=$(terraform workspace show)
echo "Using workspace '$WORKSPACE'"

echo "Running plan"
terraform plan \
  -out $TF_PLAN_FILE \
  -var "creator=${CREATOR}" \
  -var-file "./variables/${ENV}.tfvars"
echo "Plan completed"

echo "Running apply"
terraform apply $TF_PLAN_FILE
echo "Apply completed"
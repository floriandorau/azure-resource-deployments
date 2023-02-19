#!/usr/bin/env bash
set -eo pipefail

TENANT_ID=7c7b9321-129f-49df-9a90-1d150e3f40f1
SUBSCRIPTION_ID=6cb9dfe0-8839-4cc4-9e5a-3fd69da52b27
TF_PLAN_FILE=az-demo.tfplan

echo "Running init"
terraform init
echo "Init completed"

echo "Running plan"
terraform plan \
  -out $TF_PLAN_FILE \
  -var "creator=f13233" \
  -var "tenant_id=${TENANT_ID}" \
  -var "subscription_id=${SUBSCRIPTION_ID}" 
echo "Plan completed"

echo "Running apply"
terraform apply $TF_PLAN_FILE
echo "Apply completed"
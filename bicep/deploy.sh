#!/usr/bin/env bash
set -eo pipefail

datetime () { date '+%Y-%m-%dT%H:%M:%S'; }

DEPLOYMENT_NAME="azBicepDeployment"
LOCATION="westeurope"
SUBSCRPTION="6cb9dfe0-8839-4cc4-9e5a-3fd69da52b27"
LOG="bicep-$(datetime).log"
TEMPLATE_FILE="main.bicep"

echo "Deploying resources from ${TEMPLATE_FILE}"
az deployment sub create \
  --name $DEPLOYMENT_NAME \
  --location $LOCATION \
  --template-file $TEMPLATE_FILE \
  --subscription $SUBSCRPTION \
  --parameters location=$LOCATION \
  --output table > "$LOG"
echo "Resources successfully deployed"
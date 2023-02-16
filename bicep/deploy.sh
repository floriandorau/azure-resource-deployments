#!/usr/bin/env bash
set -eo pipefail

LOCATION="westeurope"
SUBSCRPTION="6cb9dfe0-8839-4cc4-9e5a-3fd69da52b27"

echo "#- Deployinf Bicep resources"
az deployment sub create \
  --name myStorageDeployment1 \
  --location $LOCATION \
  --template-file main.bicep \
  --subscription $SUBSCRPTION \
  --parameters location=$LOCATION
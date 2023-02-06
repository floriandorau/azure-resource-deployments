#!/usr/bin/env bash
set -eo pipefail

datetime () { date '+%Y-%m-%dT%H:%M:%S'; }

random () { openssl rand -hex 20; }

LOCATION="westeurope"
SUBSCRPTION="6cb9dfe0-8839-4cc4-9e5a-3fd69da52b27"
TAGS="created=$(datetime) creator=f13233"
LOG="az-$(datetime).log"

# Resource group
RESOURCE_GROUP_NAME="az-deploy-demo-azcli-rg"

echo "#- Creating resource group: ${RESOURCE_GROUP_NAME}"
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --subscription $SUBSCRPTION \
    --only-show-errors \
    --output table \
    --tags $TAGS > "$LOG"
echo "Resource group created"


# VNet
VNET_NAME="az-deploy-demo-vnet"
VNET_DB_SUBNET_NAME="az-deploy-demo-db-subnet"
VNET_WEBAPP_SUBNET_NAME="az-deploy-demo-webapp-subnet"

echo "Creating Virtual Network: ${VNET_NAME}"
az network vnet create \
    --name $VNET_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --address-prefix 10.0.0.0/16 \
    --subscription $SUBSCRPTION \
    --only-show-errors \
    --output table \
    --tags $TAGS >> "$LOG"
echo "Virtual Network created"

echo "Creating Virtual Subent: ${VNET_DB_SUBNET_NAME}"
az network vnet subnet create \
    --name $VNET_DB_SUBNET_NAME \
    --address-prefixes 10.0.0.0/24 \
    --vnet-name $VNET_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --service-endpoints Microsoft.Sql \
    --subscription $SUBSCRPTION \
    --output table \
    --only-show-errors >> "$LOG"
echo "Virtual Subnet created"

echo "Creating Virtual Subent: ${VNET_WEBAPP_SUBNET_NAME}"
az network vnet subnet create \
    --name $VNET_WEBAPP_SUBNET_NAME \
    --address-prefixes 10.0.1.0/24 \
    --vnet-name $VNET_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --subscription $SUBSCRPTION \
    --service-endpoints Microsoft.Web \
    --output table \
    --only-show-errors >> "$LOG"
echo "Virtual Subnet created"

# Database server
DATABASE_SERVER_NAME="az-deploy-mssql-server"

echo "Creating MSSQL server: ${DATABASE_SERVER_NAME}"
az sql server create \
    --name $DATABASE_SERVER_NAME \
    --admin-user "$(random)!" \
    --admin-password "$(random)!" \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP_NAME \
    --minimal-tls-version 1.2 \
    --subscription $SUBSCRPTION \
    --output table \
    --only-show-errors >> "$LOG"
echo "MSSQL server created"

# Database
DATABASE_NAME="az-deploy-demo-mssql-db"

echo "Creating MSSQL database: ${DATABASE_NAME}"
az sql db create \
    --name $DATABASE_NAME \
    --server $DATABASE_SERVER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --subscription $SUBSCRPTION \
    --only-show-errors \
    --output table \
    --tags $TAGS >> "$LOG"
echo "MSSQL database created"

KEYVAULT_NAME="az-deploy-demo-kv"

echo "Creating Keyvault: ${DATABASE_NAME}"
az keyvault create \
    --name $KEYVAULT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --subscription $SUBSCRPTION \
    --only-show-errors \
    --output table \
    --tags $TAGS >> "$LOG"
echo "Keyvault created"

APP_SERVICE_PLAN_NAME="az-deploy-demo-appservice"

echo "Creating AppService Plan: ${APP_SERVICE_PLAN_NAME}"
# Vnet integration not allowed for Free tier
az appservice plan create \
    --name $APP_SERVICE_PLAN_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --is-linux \
    --sku F1 \
    --subscription $SUBSCRPTION \
    --only-show-errors \
    --output table \
    --tags $TAGS >> "$LOG"
echo "AppService Plan created"
    
WEB_APP_NAME="az-deploy-demo-webapp"
echo "Creating WebApp: ${WEB_APP_NAME}"
az webapp create \
    --name $WEB_APP_NAME \
    --plan $APP_SERVICE_PLAN_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --deployment-container-image-name nginxdemos/hello \
    --https-only \
    --subscription $SUBSCRPTION \
    --only-show-errors \
    --output table \
    --tags $TAGS >> "$LOG"
echo "WebApp created"

# Database server/VNet rule
DB_VNET_RULE="az-deploy-vnet-mssql"
echo "Creating DB VNet rule: ${DB_VNET_RULE}"
az sql server vnet-rule create \
    --name $DB_VNET_RULE \
    --resource-group $RESOURCE_GROUP_NAME \
    --server $DATABASE_SERVER_NAME \
    --vnet $VNET_NAME \
    --subnet $VNET_DB_SUBNET_NAME \
    --subscription $SUBSCRPTION \
    --output table \
    --only-show-errors >> "$LOG"
echo "DB VNet rule created"

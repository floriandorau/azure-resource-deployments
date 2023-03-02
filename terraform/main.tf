terraform {
  required_providers {
    azurerm = ">=3.44.0"
  }
}

locals {
  tags = {
    creator  = var.creator
    created  = timestamp()
    environment = var.environment
    deployed = "terraform"
  }
}

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = "az-deploy-terraform-${var.environment}-rg"
  location = var.location
  tags     = local.tags
}

module "keyVault" {
  source = "./modules/keyvault"

  name                = "az-terraform-${var.environment}-kv"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  tenant_id           = var.tenant_id
  tags                = local.tags
}

module "vNet" {
  source = "./modules/vnet"

  name                = "az-terraform-${var.environment}-vnet"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  address_spaces = ["10.0.0.0/16"]
  subnets = {
    db_subnet = {
      name              = "az-terraform-${var.environment}-db-subnet"
      address_prefixes  = ["10.0.0.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
  }
  tags = local.tags
}

module "database" {
  source = "./modules/database"

  server_name         = "az-terraform-${var.environment}-sql-server"
  db_name             = "az-terraform-${var.environment}-sql-db"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  subnet_id           = module.vNet.subnets["db_subnet"].id
  tags                = local.tags
}

module "app_service" {
  source = "./modules/webapp"

  web_app_name = "az-terraform-${var.environment}-webapp"

  enabled = false
  sku_name = "F1"

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  tags                = local.tags
}
variable "tenant_id" {
  type        = string
  description = "Tenant id where to deploy resources"
}

variable "subscription_id" {
  type        = string
  description = "Subscription id where to deploy resources"
}

variable "creator" {
  type        = string
  description = "Name to use as creator tag for deployed resources"
}

terraform {
  required_providers {
    azurerm = ">=3.44.0"
  }
}

locals {
  location = "West Europe"

  tags = {
    creator  = var.creator
    created  = timestamp()
    deployed = "terraform"
  }
}

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = "az-deploy-demo-terraform-rg"
  location = local.location
  tags     = local.tags
}

module "keyVault" {
  source = "./modules/keyvault"

  name                = "az-terraform-kv"
  location            = local.location
  resource_group_name = azurerm_resource_group.resource_group.name
  tenant_id           = var.tenant_id
  tags                = local.tags
}

module "vNet" {
  source = "./modules/vnet"

  name                = "az-terraform-vnet"
  location            = local.location
  resource_group_name = azurerm_resource_group.resource_group.name

  address_spaces = ["10.0.0.0/16"]
  subnets = {
    db_subnet = {
      name              = "az-terraforn-db-subnet"
      address_prefixes  = ["10.0.0.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
  }
  tags = local.tags
}

module "database" {
  source = "./modules/database"

  server_name         = "az-terraforn-sql-server"
  db_name             = "az-terraforn-sql-db"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = local.location
  subnet_id           = module.vNet.subnets["db_subnet"].id
  tags                = local.tags
}

module "app_service" {
  source = "./modules/webapp"

  web_app_name = "az-terraform-webapp"

  enabled = false
  sku = {
    tier = "Standard"
    size = "F1"
  }

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = local.location
  tags                = local.tags
}
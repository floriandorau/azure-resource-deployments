variable "server_name" {
  type        = string
  description = "Name of the database server"
}

variable "db_name" {
  type        = string
  description = "Name of the Database"
}

variable "resource_group_name" {
  type        = string
  description = "Name of parent Resource Group"
}

variable "location" {
  type        = string
  description = "Location of the Database"
}

variable "sku_name" {
  type        = string
  description = "SKU of the Database"
  default     = "S0"
}

variable "tags" {
  description = "Tags attached to DB resources"
  type = object({
    creator  = string
    created  = string
    deployed = string
  })
}

resource "random_uuid" "db_admin_login" {}

resource "random_password" "db_admin_password" {
  length  = 32
  special = true
}

resource "azurerm_mssql_server" "mssql_server" {
  version = "12.0"

  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login          = resource.random_uuid.db_admin_login.result
  administrator_login_password = resource.random_password.db_admin_password.result

  tags = var.tags
}

resource "azurerm_mssql_database" "mssql_database" {
  name      = var.db_name
  server_id = azurerm_mssql_server.mssql_server.id
  sku_name  = "S0"

  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"

  tags = var.tags
}
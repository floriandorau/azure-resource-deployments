variable "name" {
  type        = string
  description = "Name of the KeyVault"
}

variable "resource_group_name" {
  type        = string
  description = "Name of parent Resource Group"
}

variable "location" {
  type        = string
  description = "Location of the KeyVault"
}

variable "tenant_id" {
  type        = string
  description = "Tenant id where to create KeyVault"
}

variable "tags" {
  description = "Tags attached to KeyVault"
  type = object({
    creator  = string
    created  = string
    deployed = string
  })
}
resource "azurerm_key_vault" "key_vault" {
  tenant_id           = var.tenant_id
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  soft_delete_retention_days  = 7
  enabled_for_disk_encryption = true
  purge_protection_enabled    = false

  sku_name = "standard"
}
variable "name" {
  type        = string
  description = "Name of the VNet"
}

variable "resource_group_name" {
  type        = string
  description = "Name of parentr Resource Group"
}

variable "location" {
  type        = string
  description = "Location of the KeyVault"
}

variable "address_spaces" {
  type        = list(string)
  description = "List of ip address ranges (CIDR notatipon)"
}

variable "subnets" {
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)
  }))
  description = "List of subnet configurations"
}

variable "tags" {
  description = "Tags attached to VNet"
  type = object({
    creator  = string
    created  = string
    deployed = string
  })
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_spaces

  tags = var.tags
}

resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name              = each.value.name
  address_prefixes  = each.value.address_prefixes
  service_endpoints = each.value.service_endpoints

  virtual_network_name = azurerm_virtual_network.virtual_network.name
  resource_group_name  = azurerm_virtual_network.virtual_network.resource_group_name
}

output "subnets" {
  value = tomap({
    for s, subnet in azurerm_subnet.subnet : s => {
      id   = subnet.id
      name = subnet.name
    }
  })
}
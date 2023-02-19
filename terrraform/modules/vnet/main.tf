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
  type = list(object({
    name           = string
    address_prefix = string
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

  address_space = var.address_spaces

  dynamic "subnet" {
    for_each = var.subnets
    content {
      name           = subnet.value["name"]
      address_prefix = subnet.value["address_prefix"]
    }
  }

  tags = var.tags
}

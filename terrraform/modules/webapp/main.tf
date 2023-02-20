variable "web_app_name" {
  type        = string
  description = "Name of the WebApp"
  validation {
    condition     = length(var.web_app_name) >= 2
    error_message = "web_app_name should have minium length 2"
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of parent Resource Group"
}

variable "location" {
  type        = string
  description = "Location of the WebApp"
}

variable "enabled" {
  type        = bool
  description = "Flag if WebApp should be enabled"
  default     = true
}

variable "sku" {
  description = "The SKU of App Service Plan"
  type = object({
    tier = string
    size = string
  })
  default = {
    tier = "Standard"
    size = "S1"
  }
}

variable "tags" {
  description = "Tags attached to WebApp"
  type = object({
    creator  = string
    created  = string
    deployed = string
  })
}


resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.web_app_name}-appserviceplan"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku {
    size = var.sku.size
    tier = var.sku.tier

  }

  tags = var.tags
}

resource "azurerm_linux_web_app" "web_app" {
  name                = var.web_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_app_service_plan.app_service_plan.id
  enabled             = var.enabled
  https_only          = true

  site_config {
    always_on = false
  }

  tags = var.tags
}
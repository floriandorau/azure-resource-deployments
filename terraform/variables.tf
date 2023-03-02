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

variable "location" {
  type        = string
  description = "Region where to deploy resources"
}

variable "environment" {
  type        = string
  description = "Name of the environment where resources belong to"
}
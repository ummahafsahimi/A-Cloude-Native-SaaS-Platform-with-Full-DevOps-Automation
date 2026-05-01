variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "inventory-vpc"
}

variable "region" {
  description = "Default region for resources"
  type        = string
  default     = "northamerica-northeast2"
}

variable "zone" {
  description = "Default zone for resources"
  type        = string
  default     = "northamerica-northeast2-a" 
}

variable "location" {
  type        = string
  description = "Azure region to deploy resources into"
  default     = "southcentralus"

  validation {
    condition     = contains(["southcentralus", "northcentralus"], var.location)
    error_message = "Only South Central US and North Central US are permitted."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"

  validation {
    condition     = contains(["prod", "dev", "qa", "sndbx"], var.environment)
    error_message = "Environment must be prod, dev, qa, or sndbx."
  }
}

variable "application_name" {
  type        = string
  description = "Name of the application or workload"
  default     = "zredundancy"
}

variable "vm_admin_username" {
  type        = string
  description = "Admin username for virtual machines"
  sensitive   = true
}

variable "vm_admin_password" {
  type        = string
  description = "Admin password for virtual machines"
  sensitive   = true
}

variable "sql_admin_username" {
  type        = string
  description = "Admin username for SQL servers"
  sensitive   = true
}

variable "sql_admin_password" {
  type        = string
  description = "Admin password for SQL servers"
  sensitive   = true
}

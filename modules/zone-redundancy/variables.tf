variable "config" {
  description = "Zone redundancy configuration loaded from YAML"
  type = object({
    load_balancer = object({
      name = string
      sku  = string
    })
    virtual_machines = list(object({
      name = string
      size = string
      zone = string
    }))
    storage = object({
      name        = string
      replication = string
    })
    sql_servers = list(object({
      name           = string
      zone_redundant = bool
      databases = list(object({
        name = string
        sku  = string
      }))
    }))
  })
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy into"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vm_admin_username" {
  type      = string
  sensitive = true
}

variable "vm_admin_password" {
  type      = string
  sensitive = true
}

variable "sql_admin_username" {
  type      = string
  sensitive = true
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where VMs will be placed"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}

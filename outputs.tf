# ─────────────────────────────────────────────────────
# ROOT OUTPUTS.TF
# Prints useful information after terraform apply.
# This is what you see in the terminal when done.
# Also visible in GitHub Actions pipeline logs.
# ─────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "environment" {
  description = "Which environment was deployed"
  value       = var.environment
}

output "location" {
  description = "Azure region deployed to"
  value       = var.location
}

output "load_balancer_public_ip" {
  description = "Public IP of the Load Balancer"
  value       = module.zone_redundancy.load_balancer_public_ip
}

output "vm_zones" {
  description = "Proves zone redundancy — shows which zone each VM is in"
  value       = module.zone_redundancy.vm_zones
}

output "storage_replication_type" {
  description = "ZRS in prod LRS in dev — confirms zone redundancy setting"
  value       = module.zone_redundancy.storage_replication_type
}

output "sql_server_ids" {
  description = "SQL server IDs"
  value       = module.zone_redundancy.sql_server_ids
}

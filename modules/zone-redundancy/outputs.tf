output "load_balancer_id" {
  description = "The ID of the Load Balancer"
  value       = azurerm_lb.this.id
}

output "load_balancer_public_ip" {
  description = "The public IP address of the Load Balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "vm_ids" {
  description = "Map of VM names to their IDs"
  value       = { for k, v in azurerm_linux_virtual_machine.this : k => v.id }
}

output "vm_zones" {
  description = "Map of VM names to their zones — proves zone redundancy"
  value       = { for k, v in azurerm_linux_virtual_machine.this : k => v.zone }
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "storage_replication_type" {
  description = "Storage replication type — ZRS in prod LRS in dev"
  value       = azurerm_storage_account.this.account_replication_type
}

output "sql_server_ids" {
  description = "Map of SQL server names to their IDs"
  value       = { for k, v in azurerm_mssql_server.this : k => v.id }
}

# ─────────────────────────────────────────────────────
# ROOT MAIN.TF
# Reads the YAML config and calls the zone redundancy
# module. This is the only file that changes between
# environments — just point it at a different YAML.
# ─────────────────────────────────────────────────────

# ── READ THE YAML CONFIG ──────────────────────────────
# yamldecode() reads the YAML file and converts it
# into a Terraform object the module can consume.
# Change the file path to switch environments.
locals {
  config = yamldecode(file("${path.module}/config/${var.environment}.yaml"))
}

# ── RESOURCE GROUP ────────────────────────────────────
# Every resource in Azure must live in a resource group.
# This is free — just a logical container.
resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.required_tags
}

# ── VIRTUAL NETWORK ───────────────────────────────────
# VMs need a network to live in.
# Using generic IP range — not Permian specific.
resource "azurerm_virtual_network" "this" {
  name                = "az-vnet-${local.region_short}-${var.application_name}-${var.environment}-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.required_tags
}

# ── SUBNET ────────────────────────────────────────────
# VMs live in this subnet.
# Subnet is carved out of the VNet address space.
resource "azurerm_subnet" "this" {
  name                 = "az-snet-${local.region_short}-${var.application_name}-${var.environment}-001"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ── NETWORK SECURITY GROUP ────────────────────────────
# Controls traffic in and out of the subnet.
# Applied to the subnet — not individual VMs.
resource "azurerm_network_security_group" "this" {
  name                = "az-nsg-${local.region_short}-${var.application_name}-${var.environment}-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.required_tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# ── ZONE REDUNDANCY MODULE ────────────────────────────
# This calls the module we built.
# Passes the YAML config and all required inputs.
# The module builds everything — LB, VMs, Storage, SQL.
module "zone_redundancy" {
  source = "./modules/zone-redundancy"

  # Pass the zone_redundancy block from the YAML
  # prod.yaml → 3 zones, ZRS, zone_redundant: true
  # dev.yaml  → 2 zones, LRS, zone_redundant: false
  config = local.config.zone_redundancy

  # Infrastructure inputs
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  subnet_id           = azurerm_subnet.this.id

  # Credentials — passed from variables
  # Never hardcoded — comes from terminal or GitHub Secrets
  vm_admin_username  = var.vm_admin_username
  vm_admin_password  = var.vm_admin_password
  sql_admin_username = var.sql_admin_username
  sql_admin_password = var.sql_admin_password

  tags = local.required_tags
}

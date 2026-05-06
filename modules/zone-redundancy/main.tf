# ─────────────────────────────────────────────────────
# MODULES/ZONE-REDUNDANCY/MAIN.TF
# Builds all zone redundant resources.
# Reads everything from var.config which comes
# from the YAML file via yamldecode() in root main.tf
# ─────────────────────────────────────────────────────

# ── LAYER 1: LOAD BALANCER ────────────────────────────
# Standard SKU Load Balancer with zone redundant
# Public IP — the entry point for all traffic.
# Health probes check VMs every 5 seconds.
# Zone 1 goes down → traffic automatically
# redistributes to Zone 2 and Zone 3.

resource "azurerm_public_ip" "lb" {
  name                = "${var.config.load_balancer.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  # Standard SKU Public IP = automatically zone redundant
  # Basic SKU does NOT support zone redundancy
  zones               = ["1", "2", "3"]
  # Pinned to all 3 zones — survives any single zone failure
  tags                = var.tags
}

resource "azurerm_lb" "this" {
  name                = var.config.load_balancer.name
  # Name comes from YAML — az-lb-scus-zredundancy-prod-001
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.config.load_balancer.sku
  # SKU comes from YAML — Standard

  frontend_ip_configuration {
    name                 = "frontend-zone-redundant"
    public_ip_address_id = azurerm_public_ip.lb.id
    # References the zone redundant Public IP above
    # Standard LB + Standard IP = zone redundant frontend
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "this" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.this.id
  # This pool holds all the VMs
  # Load Balancer distributes traffic across pool members
}

resource "azurerm_lb_probe" "this" {
  name            = "health-probe"
  loadbalancer_id = azurerm_lb.this.id
  protocol        = "Tcp"
  port            = 22
  # Checks port 22 every 5 seconds on each VM
  # 2 failures = VM removed from pool automatically
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "this" {
  name                           = "lb-rule-ssh"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "frontend-zone-redundant"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.this.id
  # This rule connects the frontend to the backend pool
  # Traffic comes in on port 22 → goes to VMs in the pool
}

# ── LAYER 2: VIRTUAL MACHINES ─────────────────────────
# for_each reads the virtual_machines list from YAML
# and creates one VM per entry automatically.
# prod.yaml has 3 entries → 3 VMs across 3 zones
# dev.yaml has 2 entries → 2 VMs across 2 zones
# The code never changes — only the YAML changes.

resource "azurerm_network_interface" "vm" {
  for_each = { for vm in var.config.virtual_machines : vm.name => vm }
  # This line is the for_each loop
  # for vm in var.config.virtual_machines → loop over VM list
  # vm.name => vm → use VM name as the key
  # Result: one NIC per VM entry in YAML

  name                = "${each.value.name}-nic"
  # each.value.name = current VM name from YAML
  # Example: az-vm-scus-zredundancy-prod-001-nic
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    # Azure assigns a private IP automatically
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "vm" {
  for_each = { for vm in var.config.virtual_machines : vm.name => vm }
  # Same for_each — one association per VM
  # Connects each VM's NIC to the Load Balancer pool

  network_interface_id    = azurerm_network_interface.vm[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each = { for vm in var.config.virtual_machines : vm.name => vm }
  # Same for_each pattern — creates one VM per YAML entry
  # This is exactly what Jose showed in the IaC meeting

  name                = each.value.name
  # Name comes from YAML
  # Example: az-vm-scus-zredundancy-prod-001

  location            = var.location
  resource_group_name = var.resource_group_name

  size                = each.value.size
  # VM size comes from YAML
  # prod.yaml: Standard_B1s
  # dev.yaml: Standard_B1s

  zone                = each.value.zone
  # ZONE COMES FROM YAML — this is the key line
  # prod VM 1 → zone = "1"
  # prod VM 2 → zone = "2"
  # prod VM 3 → zone = "3"
  # dev VM 1  → zone = "1"
  # dev VM 2  → zone = "2"

  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  # Credentials come from variables — never hardcoded
  # In GitHub Actions these come from TF_VAR_ secrets
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vm[each.key].id
    # Connects this VM to its matching NIC
    # each.key = VM name — matches the NIC created above
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    # Premium SSD for OS disk — good performance
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
    # Ubuntu 22.04 LTS — free to use
    # No Windows license cost for practice
  }

  tags = var.tags
}

# ── LAYER 3: ZONE REDUNDANT STORAGE ───────────────────
# One setting change makes storage zone redundant.
# account_replication_type = ZRS → 3 copies across 3 zones
# account_replication_type = LRS → 3 copies in 1 zone only
# prod.yaml sends ZRS → zone redundant
# dev.yaml sends LRS → not zone redundant — saves cost

resource "azurerm_storage_account" "this" {
  name                = var.config.storage.name
  # Name comes from YAML
  # prod: stzredprod001
  # dev:  stzreddev001

  resource_group_name = var.resource_group_name
  location            = var.location
  account_tier        = "Standard"

  account_replication_type      = var.config.storage.replication
  # THIS IS THE KEY LINE FOR ZONE REDUNDANCY
  # prod.yaml sends ZRS → zone redundant across 3 zones
  # dev.yaml sends LRS → single zone — saves cost
  # Same code — different YAML value — different behavior

  public_network_access_enabled = false
  # No public access — private only
  # Best practice for any storage account

  tags = var.tags
}

# ── LAYER 4: ZONE REDUNDANT SQL ───────────────────────
# Two for_each loops — one for servers, one for databases.
# This is exactly the pattern Jose showed in the meeting.
# YAML drives how many servers and databases get created.

resource "azurerm_mssql_server" "this" {
  for_each = { for s in var.config.sql_servers : s.name => s }
  # Loop over sql_servers list from YAML
  # Creates one SQL server per entry

  name                         = each.value.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  # Credentials from variables — never hardcoded

  tags = var.tags
}

resource "azurerm_mssql_database" "this" {
  # Nested for_each — loops over servers AND databases
  # This flattens the nested YAML structure into a flat map
  # so Terraform can create each database individually
  for_each = {
    for pair in flatten([
      for server in var.config.sql_servers : [
        for db in server.databases : {
          key            = "${server.name}__${db.name}"
          # Unique key combining server and database names
          server_name    = server.name
          db_name        = db.name
          sku            = db.sku
          zone_redundant = server.zone_redundant
          # Zone redundancy setting inherited from server
          # prod server: zone_redundant = true
          # dev server: zone_redundant = false
        }
      ]
    ]) : pair.key => pair
  }

  name      = each.value.db_name
  server_id = azurerm_mssql_server.this[each.value.server_name].id
  # References the SQL server created above
  # each.value.server_name matches the server key

  sku_name       = each.value.sku
  zone_redundant = each.value.zone_redundant
  # THIS IS THE KEY LINE FOR DATABASE ZONE REDUNDANCY
  # prod.yaml → zone_redundant: true → replicas across zones
  # dev.yaml  → zone_redundant: false → single zone — saves cost

  tags = var.tags
}
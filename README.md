# Azure Terraform Zone Redundancy

A Terraform module demonstrating Azure Availability Zone redundancy using a YAML-driven infrastructure pattern.

## What This Demonstrates

This repo shows how to build Azure infrastructure that survives a zone failure with zero downtime and no manual failover required. It uses the same YAML-driven pattern used in enterprise Azure Landing Zone deployments.

## The Core Concept

Traditional approach: zones hardcoded in Terraform files — does not scale.

This approach: zones defined in YAML config files. Terraform module reads the YAML and builds whatever is defined. Change the YAML, change the infrastructure. The Terraform code never changes between environments.

## How the YAML Pattern Works

prod.yaml gives you full zone redundancy:
- 3 VMs across 3 zones
- ZRS storage — 3 copies across 3 zones
- zone_redundant true on SQL

dev.yaml gives you cost optimized setup:
- 2 VMs across 2 zones
- LRS storage — cheaper
- zone_redundant false on SQL

Same Terraform code runs both. Only the YAML changes.

## Key Concepts Demonstrated

- YAML-driven configuration with yamldecode()
- for_each loops over YAML lists
- Nested for_each for SQL servers and databases
- Module pattern — written once, called per environment
- sensitive = true on credential variables
- Validation blocks enforcing region restrictions
- Zone redundant Load Balancer with health probes
- VM zone pinning from YAML
- ZRS vs LRS storage driven by YAML
- zone_redundant flag on SQL driven by YAML

## Usage

Step 1 — Initialize Terraform:
terraform init

Step 2 — Plan for dev environment:
terraform plan \
  -var="environment=dev" \
  -var="vm_admin_username=YOUR_USERNAME" \
  -var="vm_admin_password=YOUR_PASSWORD" \
  -var="sql_admin_username=YOUR_SQL_USERNAME" \
  -var="sql_admin_password=YOUR_SQL_PASSWORD"

Step 3 — Plan for prod environment:
terraform plan \
  -var="environment=prod" \
  -var="vm_admin_username=YOUR_USERNAME" \
  -var="vm_admin_password=YOUR_PASSWORD" \
  -var="sql_admin_username=YOUR_SQL_USERNAME" \
  -var="sql_admin_password=YOUR_SQL_PASSWORD"

Note: Credentials are passed as variables at runtime and never stored in code.

## Dev vs Prod Plan Output

Dev plan output:
  storage_replication_type = "LRS"
  vm_zones = {
    az-vm-scus-zredundancy-dev-001 = "1"
    az-vm-scus-zredundancy-dev-002 = "2"
  }

Prod plan output:
  storage_replication_type = "ZRS"
  vm_zones = {
    az-vm-scus-zredundancy-prod-001 = "1"
    az-vm-scus-zredundancy-prod-002 = "2"
    az-vm-scus-zredundancy-prod-003 = "3"
  }

Same code. Different YAML. Different infrastructure.

## Author

Harry Abongwa
Cloud Engineer — Azure Infrastructure and IaC

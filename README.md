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

terraform init

terraform plan for dev:
terraform plan -var="environment=dev" -var="vm_admin_username=adminuser" -var="vm_admin_password=YourPassword123!" -var="sql_admin_username=sqladmin" -var="sql_admin_password=YourPassword123!"

terraform plan for prod:
terraform plan -var="environment=prod" -var="vm_admin_username=adminuser" -var="vm_admin_password=YourPassword123!" -var="sql_admin_username=sqladmin" -var="sql_admin_password=YourPassword123!"

## Author

Harry Abongwa
Cloud Engineer — Azure Infrastructure and IaC

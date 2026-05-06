locals {
  region_short = var.location == "southcentralus" ? "scus" : "ncus"

  name_prefix = "az-${local.region_short}-${var.application_name}-${var.environment}"

  resource_group_name = "az-rg-${local.region_short}-${var.application_name}-${var.environment}-001"

  required_tags = {
    ApplicationName = var.application_name
    Env             = var.environment
    DR              = var.environment == "prod" ? "Mission Critical" : "Essential"
    CostCenter      = "PERSONAL-PRACTICE"
    BusinessOwner   = "harry.abongwa@personal.com"
    Maintenance     = "M-23:59-02:00"
    DataClass       = "Public"
    Patch           = "Window1"
    CreatedBy       = "terraform"
  }
}

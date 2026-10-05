locals {
  is_production = var.environment == "prod"

  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
  })
}

locals {
  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
  })
}

locals {
  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
  })

  private_subnets = {
    for name, subnet in var.subnets :
    name => subnet if subnet.tier != "public"
  }
}

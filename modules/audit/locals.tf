locals {
  trail_name = "${var.name_prefix}-trail"

  trail_arn = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"

  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
  })
}

output "environment" {
  description = "Selected Terraform workspace."
  value       = local.env
}

output "vpc_id" {
  description = "ID of the environment's VPC."
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "Configured IPv4 CIDR of the VPC."
  value       = local.vpc_cidr
}

output "vpc_public_subnet_info" {
  description = "Public subnet IDs and CIDRs keyed by subnet name."

  value = {
    for name, subnet_id in module.network.public_subnet_ids : name => {
      id         = subnet_id
      cidr_block = module.network.public_subnet_cidrs[name]
    }
  }
}

output "vpc_application_subnet_info" {
  description = "Application subnet IDs and CIDRs keyed by subnet name."

  value = {
    for name, subnet_id in module.network.application_subnet_ids : name => {
      id         = subnet_id
      cidr_block = module.network.application_subnet_cidrs[name]
    }
  }
}

output "vpc_database_subnet_info" {
  description = "Database subnet IDs and CIDRs keyed by subnet name."

  value = {
    for name, subnet_id in module.network.database_subnet_ids : name => {
      id         = subnet_id
      cidr_block = module.network.database_subnet_cidrs[name]
    }
  }
}

output "instance_info" {
  value = {
    id          = module.compute.instance_id
    private_ip  = module.compute.private_ip
    private_dns = module.compute.private_dns
  }
}

output "flow_logs" {
  value = module.network.flow_logs
}

output "database_info" {
  value = module.rds.database_info
}

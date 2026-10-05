output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = {
    for name, subnet in aws_subnet.this :
    name => subnet.id if var.subnets[name].tier == "public"
  }
}

output "application_subnet_ids" {
  value = {
    for name, subnet in aws_subnet.this :
    name => subnet.id if var.subnets[name].tier == "application"
  }
}

output "database_subnet_ids" {
  value = {
    for name, subnet in aws_subnet.this :
    name => subnet.id if var.subnets[name].tier == "database"
  }
}

output "public_subnet_cidrs" {
  value = {
    for name, subnet in aws_subnet.this :
    name => subnet.cidr_block if var.subnets[name].tier == "public"
  }
}

output "application_subnet_cidrs" {
  value = {
    for name, subnet in aws_subnet.this :
    name => subnet.cidr_block if var.subnets[name].tier == "application"
  }
}

output "database_subnet_cidrs" {
  value = {
    for name, subnet in aws_subnet.this :
    name => subnet.cidr_block if var.subnets[name].tier == "database"
  }
}

output "flow_logs" {
  description = "VPC flow-log ID and destination log group."

  value = {
    id             = aws_flow_log.this.id
    log_group_name = aws_cloudwatch_log_group.flow_logs.name
  }
}

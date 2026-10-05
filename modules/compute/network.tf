
resource "aws_security_group" "instance" {
  name_prefix = "${var.name_prefix}-instance-"
  description = "Private EC2 instance access."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-instance"
  })
}

resource "aws_security_group" "endpoints" {
  name_prefix = "${var.name_prefix}-endpoints-"
  description = "Systems Manager endpoint access."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-endpoints"
  })
}

resource "aws_vpc_security_group_egress_rule" "instance_to_endpoints" {
  security_group_id            = aws_security_group.instance.id
  referenced_security_group_id = aws_security_group.endpoints.id
  description                  = "HTTPS to Systems Manager endpoints."
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_instance" {
  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.instance.id
  description                  = "HTTPS from private EC2 instances."
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = toset(["ssm", "ssmmessages"])

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = values(var.application_subnet_ids)
  security_group_ids = [aws_security_group.endpoints.id]

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}"
  })
}
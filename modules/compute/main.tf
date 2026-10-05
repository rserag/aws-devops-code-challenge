resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.instance_subnet_id

  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.instance.id]
  iam_instance_profile        = aws_iam_instance_profile.instance.name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-instance"
  })

  volume_tags = local.common_tags

  depends_on = [
    aws_iam_role_policy.session_manager,
    aws_vpc_endpoint.ssm,
    aws_vpc_security_group_egress_rule.instance_to_endpoints,
    aws_vpc_security_group_ingress_rule.endpoints_from_instance
  ]
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-database"
  subnet_ids = values(var.database_subnet_ids)

  tags = local.common_tags
}

resource "aws_security_group" "database" {
  name_prefix = "${var.name_prefix}-database-"
  description = "Database access from application instances."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-database"
  })
}

resource "aws_vpc_security_group_ingress_rule" "from_application" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = var.application_security_group_id
  description                  = "PostgreSQL from application instances."
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

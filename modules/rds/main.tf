resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-database"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name                     = var.db_name
  username                    = var.master_username
  manage_master_user_password = true

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  port                   = 5432

  multi_az                   = local.is_production
  backup_retention_period    = local.is_production ? 7 : 1
  auto_minor_version_upgrade = true

  deletion_protection       = local.is_production
  skip_final_snapshot       = !local.is_production
  final_snapshot_identifier = local.is_production ? "${var.name_prefix}-final" : null

  copy_tags_to_snapshot = true
  tags                  = local.common_tags
}

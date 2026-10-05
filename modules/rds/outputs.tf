output "security_group_id" {
  value = aws_security_group.database.id
}

output "database_info" {
  value = {
    address    = aws_db_instance.this.address
    port       = aws_db_instance.this.port
    db_name    = aws_db_instance.this.db_name
    username   = aws_db_instance.this.username
    secret_arn = aws_db_instance.this.master_user_secret[0].secret_arn
  }
}

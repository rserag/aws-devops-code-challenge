module "audit" {
  source = "../modules/audit"

  name_prefix     = "devops-account"
  log_bucket_name = "devops-challenge-audit-${data.aws_caller_identity.current.account_id}-eu-north-1"

  tags = {
    Project     = "devops-code-challenge"
    Environment = "shared"
  }
}

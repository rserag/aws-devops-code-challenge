terraform {
  backend "s3" {
    bucket       = "tf-state-rafayel-task-731776047142-eu-north-1"
    key          = "account-security/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}

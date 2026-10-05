terraform {
  backend "s3" {
    bucket               = "tf-state-rafayel-task-731776047142-eu-north-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "environments"
    region               = "eu-north-1"
    encrypt              = true
    use_lockfile         = true
  }
}

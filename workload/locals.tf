locals {
  env = terraform.workspace

  vpc_cidrs = {
    stg  = "10.20.0.0/16"
    prod = "10.30.0.0/16"
  }

  vpc_cidr = local.vpc_cidrs[local.env]

  subnet_layout = {
    public-a = { az = "eu-north-1a", number = 0, tier = "public" }
    public-b = { az = "eu-north-1b", number = 1, tier = "public" }

    app-a = { az = "eu-north-1a", number = 10, tier = "application" }
    app-b = { az = "eu-north-1b", number = 11, tier = "application" }

    db-a = { az = "eu-north-1a", number = 20, tier = "database" }
    db-b = { az = "eu-north-1b", number = 21, tier = "database" }
  }
}

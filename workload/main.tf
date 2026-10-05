module "network" {
  source = "../modules/network"

  name_prefix             = "devops-${local.env}"
  vpc_cidr                = local.vpc_cidr
  flow_log_retention_days = local.env == "prod" ? 30 : 7

  subnets = {
    for name, subnet in local.subnet_layout : name => {
      cidr_block        = cidrsubnet(local.vpc_cidr, 8, subnet.number)
      availability_zone = subnet.az
      tier              = subnet.tier
    }
  }

  tags = {
    Project     = "devops-code-challenge"
    Environment = local.env
  }
}

module "compute" {
  source = "../modules/compute"

  name_prefix            = "devops-${local.env}"
  vpc_id                 = module.network.vpc_id
  application_subnet_ids = module.network.application_subnet_ids
  instance_subnet_id     = module.network.application_subnet_ids["app-a"]
  instance_type          = "t3.micro"
  ami_id                 = var.ami_id

  tags = {
    Project     = "devops-code-challenge"
    Environment = local.env
  }
}

module "rds" {
  source = "../modules/rds"

  name_prefix                   = "devops-${local.env}"
  environment                   = local.env
  vpc_id                        = module.network.vpc_id
  database_subnet_ids           = module.network.database_subnet_ids
  application_security_group_id = module.compute.security_group_id
  instance_class                = "db.t3.micro"

  tags = {
    Project     = "devops-code-challenge"
    Environment = local.env
  }
}

resource "aws_vpc_security_group_egress_rule" "application_to_database" {
  security_group_id            = module.compute.security_group_id
  referenced_security_group_id = module.rds.security_group_id
  description                  = "PostgreSQL to the database."
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

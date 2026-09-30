module "vpc" {
  source              = "./modules/vpc"
  name                = "technova-vpc"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  azs                 = ["us-east-1a"]
  tags = {
    Project = "TechNova"
    Env     = "lab"
  }
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
  tags   = { Project = "TechNova", Env = "lab" }
}

module "compute" {
  source            = "./modules/compute"
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security.app_security_group_id
  instance_profile  = "LabInstanceProfile"
  repo_url          = "https://github.com/crocodiles128/prova-primeiro-bimestre-devops.git"
  database_url      = "postgresql://postgres:${var.db_password}@${module.rds.endpoint}:5432/technova"
  app_port          = "3000"
  instance_type     = "t3.micro"
  tags              = { Project = "TechNova", Env = "lab" }
}

module "rds" {
  source = "./modules/rds"

  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.security.rds_security_group_id
  db_password           = var.db_password

  tags = {
    Project = "TechNova"
    Env     = "lab"
  }
}

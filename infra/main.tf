module "vpc" {
	source             = "./modules/vpc"
	name               = "technova-vpc"
	vpc_cidr           = "10.0.0.0/16"
	public_subnet_cidr = "10.0.1.0/24"
	private_subnet_cidr= "10.0.2.0/24"
	azs                = ["us-east-1a"]
	tags = {
		Project = "TechNova"
		Env     = "lab"
	}
}

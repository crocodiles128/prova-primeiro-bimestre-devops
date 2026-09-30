provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project = "TechNova"
      Course  = "DevOps"
      Env     = "Lab"
    }
  }
}

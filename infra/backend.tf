terraform {
  backend "s3" {
    bucket         = "technova-terraform-state-20532120"
    key            = "technova/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "technova-terraform-locks"
    encrypt        = true
  }
}

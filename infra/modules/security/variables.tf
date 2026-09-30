variable "vpc_id" {
  type        = string
  description = "VPC id where security groups will be created"
}

variable "app_sg_name" {
  type        = string
  description = "Name for the application security group"
  default     = "technova-app-sg"
}

variable "rds_sg_name" {
  type        = string
  description = "Name for the RDS security group"
  default     = "technova-rds-sg"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

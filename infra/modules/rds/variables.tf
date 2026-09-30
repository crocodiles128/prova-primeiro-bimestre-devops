variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids for RDS DB subnet group"
}

variable "rds_security_group_id" {
  type        = string
  description = "Security group ID to attach to RDS"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

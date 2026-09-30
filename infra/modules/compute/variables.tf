variable "subnet_id" {
  type        = string
  description = "Subnet ID to launch the EC2 instance in"
}

variable "security_group_id" {
  type        = string
  description = "Security Group ID to attach to instance"
}

variable "instance_profile" {
  type        = string
  description = "IAM instance profile name to attach to the instance"
}

variable "repo_url" {
  type        = string
  description = "Git repository URL for the application"
}

variable "database_url" {
  type        = string
  description = "Database connection string for the app"
  sensitive   = true
}

variable "app_port" {
  type        = string
  description = "Port the app will listen on"
  default     = "3000"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "ami_id" {
  type        = string
  description = "Optional: override AMI id"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply"
  default     = {}
}

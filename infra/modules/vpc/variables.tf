variable "name" {
  type        = string
  description = "Name prefix for resources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones to use"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "private_subnet_cidr_2" {
  type        = string
  description = "CIDR block for the second private subnet"
  default     = "10.0.3.0/24"
}

variable "private_subnet_az" {
  type        = string
  description = "Availability zone for the second private subnet"
  default     = "us-east-1b"
}

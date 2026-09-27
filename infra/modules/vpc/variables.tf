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

########################################
# General / user-supplied parameters
# (surfaced as workflow_dispatch inputs)
########################################
variable "aws_region" {
  description = "AWS region to deploy the base VPC into."
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Name prefix applied to resource tags."
  type        = string
  default     = "base-infra"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "Two AZs used for the public and private subnets."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-12b"]
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (AZ 1)."
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (AZ 2)."
  type        = string
  default     = "10.10.2.0/24"
}

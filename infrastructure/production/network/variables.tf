
variable "aws_region" {
  description = "AWS Region where the resources will be created"
  default     = "eu-west-1"
}

variable "vpc_cidr_block" {
  description = "CIDR Block for the main VPC"
  default     = "10.0.0.0/16"
}

variable "ops_terraformed" {
  description = "Indication of the resource being created via terraform. Must be true for all resources created through modules"
  default     = true
}

variable "availability_zone" {
  description = "Availability zone"
  default     = "eu-west-1"
}

variable "az1_cidr_block" {
  description = "CIDR Block for the AZ1"
  default     = "10.0.0.0/24"
}
variable "region" {
  description = "Region to deploy resources to aws region"
  type        = string
  default     = "us-east-1"
}


variable "availability_zone" {
  description = "Availability zone to deploy resources to aws region"
  type        = string
  default     = "us-east-1a"
}



variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}


variable "public_subnet_cidrs" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_1_cidrs" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_subnet_2_cidrs" {
  type    = string
  default = "10.0.3.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}



variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-934c72d7d280413d9"
}



variable "project_name" {
  description = "project name"
  type        = string
  default     = "vera-3tier"
}

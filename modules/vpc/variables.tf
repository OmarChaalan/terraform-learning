variable "region" {
    description = "AWS region"
    type = string
}

variable "environment" {
    description = "Environment name"
    type = string
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
}

variable "availability_zones" {
    description = "AZs list to deploy subnets into"
    type = list(string)
}

variable "public_subnet_cidrs" {
    description = "CIDR blocks for public subnets"
    type = list(string)
}

variable "private_subnet_cidrs" {
    description = "CIDR blocks for private subnets"
    type = list(string)
}

variable "common_tags" {
    description = "Common tags to apply to all resources"
    type = map(string)
}

variable "my_ip" {
    description = "IP for ssh access, x.x.x.x/32"
    type = string
}
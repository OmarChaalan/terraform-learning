variable "region" { 
    description = "AWS region where the resources are deployed"
    type = string
    default = "us-east-1"
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "environment" {
    description = "Environment name: dev, staging, or production"
    type = string
    default = "dev"
}

variable "enable_dns" {
    description = "Whether to enable DNS support and hostnames in the VPC"
    type = bool
    default = true
}

variable "availability_zones" {
    description = "List of AZs to deploy subnets into"
    type = list(string)
    default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
    description = "CIDR blocks for public subnets in the VPC"
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
    description = "CIDR blocks for private subnets in the VPC"
    type = list(string)
    default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}
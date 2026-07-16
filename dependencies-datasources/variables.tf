variable "region" {
    description = "AWS Region to deploy resources to"
    type = string
    default = "us-east-1"
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "environment" {
    description = "Environment to deploy in: production, testing, or dev"
    type = string
    default = "dev"
}

variable "availability_zones" {
    description = "List of AZs to deploy the subnets to"
    type = list(string)
    default = ["us-east-1a", "us-east-1b"]
}

variable "enable_dns" {
    description = "Whether to enable DNS support and hostnames for the vpc"
    type = bool
    default = true
}

variable "public_subnet_cidrs" {
    description = "CIDR block for the public subnets"
    type = list(string) 
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
    description = "CIDR block for the private subnets" 
    type = list(string)
    default = ["10.0.3.0/24", "10.0.4.0/24"]
}


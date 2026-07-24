variable "region" {
    description = "Which region the resources will be deployed in"
    type = string
    default = "us-east-1"
}

variable "environment" {
    description = "Which environment to deploy in: production, dev, testing"
    type = string
    default = "dev"
}

variable "vpc_cidr" {
    description = "The CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "enable_dns" {
    description = "Whether to enable DNS support and hostnames for the VPC"
    type = bool
    default = true
}

variable "public_subnets_cidrs" {
    description = "The CIDR blocks for the public subnets"
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24"] 
}

variable "private_subnets_cidrs" {
    description = "The CIDR blocks for the private subnets"
    type = list(string)
    default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
    description = "AZs to deploy the subnets to"
    type = list(string)
    default = ["us-east-1a", "us-east-1b"]
}

variable "my_ip" {
    description = "IP address for ssh access, x.x.x.x/32"
    type = string
}
variable "region" {
    description = "What region the resources will be deployed in"
    type = string
    default = "us-east-1"
}

variable "environment" {
    description = "Which environment to deploy in: production, testing, dev"
    type = string
    default = "dev"
}

variable "instance_type" {
    description = "The EC2 instance type"
    type = string
    default = "t3.micro"
}

variable "cidr_block" {
    description = "VPC cidr block"
    type = string
    default = "10.0.0.0/16"
}

variable "enable_dns" {
    description = "Whether to enable DNS support and hostnames in the VPC"
    type = bool
    default = true
}

variable "public_subnets_cidrs" {
    description = "Public subnets cidr blocks"
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24"]
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
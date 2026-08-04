variable "instance_type" {
    type = string
    default = "t3.micro"
}

variable "region" {
    type = string
    default = "us-east-1"
}

variable "environment" {
    description = "Environment list: dev, staging, testing, and production"
    type = string
    default = "testing"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
    type = list(string)
    default = [ "10.0.1.0/24", "10.0.2.0/24" ]
}

variable "private_subnet_cidrs" {
    type = list(string)
    default = [ "10.0.3.0/24", "10.0.4.0/24" ]
}

variable "availability_zones" {
    type = list(string)
    default = [ "us-east-1a", "us-east-1b" ]
}

variable "my_ip" {
  type = string
}
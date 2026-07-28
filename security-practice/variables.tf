variable "region" {
    description = "Region to deploy resources in"
    type = string
    default = "us-east-1"
}

variable "environment" {
    description = "Which environment for resources: dev, prod, staging, testing"
    type = string
    default = "dev"
}
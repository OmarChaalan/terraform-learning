terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }

    backend "s3" {
        bucket = "omar-chaalan-terraform-state"
        key = "modules-practice/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-state-lock"
        encrypt = true
    }
}

provider "aws" {
    region = var.region

    default_tags {
      tags = local.common_tags 
    }
}

module "vpc" {
    source = "../modules/vpc"

    vpc_cidr = var.vpc_cidr
    environment = var.environment
    region = var.region
    availability_zones = var.availability_zones
    public_subnet_cidrs = var.public_subnet_cidrs
    private_subnet_cidrs = var.private_subnet_cidrs
    common_tags = local.common_tags
    my_ip = var.my_ip
}
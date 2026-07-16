terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "omar-chaalan-terraform-state"
    key = "variables-outputs/terraform.tfstate"
    region = var.region
    dynamodb_table = "terraform-state-lock"
    encyrpt = true
  }
}

provider "aws" {
    region = var.region

    default_tags {
        tags = local.common.tags
    }
}



resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = var.enable_dns
    enable_dns_support = var.enable_dns

    tags = {
        Name = "${local.name_prefix}-vpc"
    }
}

resource "aws_vpc" "main2" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = var.enable_dns
    enable_dns_support = var.enable_dns

    tags = {
        Name = "${local.name_prefix}-vpc2"
    }
}

resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.main
    cidr_block = var.public_subnet_cidrs[0]
    availability_zone = var.availability_zones[0]
    map_public_ip_on_launch = true

    tags = {
        Name = "${local.name_prefix}-public-subnet-1"
    }
}


resource "aws_subnet" "public-subnet-2" {
    vpc_id = aws_vpc.main
    cidr_block = var.public_subnet_cidrs[1]
    availability_zone = var.availaiblity_zones[1]
    map_public_ip_on_launch = true

    tags = {
        Name = "${local.name_prefix}-public-subnet-2"
    }
}

resource "aws_subnet" "private-subnet-1" {
    vpc_id = aws_vpc.main
    cidr_block = var.private_subnet_cidrs[0]
    availability_zone = var.availability_zones[0]
    map_public_ip_on_launch = false

    tags = {
        Name = "${local.name_prefix}-private-subnet-1"
    }
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.main
    cidr_block = var.private_subnet_cidrs[1]
    availability_zone = var.availability_zones[1]
    map_public_ip_on_launch = false

    tags = {
        Name = "${local.name_prefix}-private-subnet-2"
    }
}
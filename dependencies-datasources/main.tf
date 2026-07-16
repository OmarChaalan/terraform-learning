terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }

    backend "s3" {
        bucket = "omar-chaalan-terraform-state"
        key = "dependencies-datasources/terraform.tfstate"
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


data "aws_availability_zones" "available" {
    state = "available"
}

data "aws_caller_identity" "current" {

}

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["al2023-ami-*-x86_64"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
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

resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[0]
    availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true

    tags = {
        Name = "${local.name_prefix}-public-subnet-1"
    }
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[1]
    availability_zone = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = true

    tags = {
        Name = "${local.name_prefix}-public-subnet-2"
    }
}

resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[0]
    availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = false

    tags = {
        Name = "${local.name_prefix}-private-subnet-1"
    }
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[1]
    availability_zone = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = false

    tags = {
        Name = "${local.name_prefix}-private-subnet-2"
    }
}

resource "aws_instance" "app_server" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
}

data "aws_vpc" "default" {
    default = true
}

resource "aws_subnet" "new_subnet" {
    vpc_id = data.aws_vpc.default.id
    cidr_block = "172.31.100.0/24"
}
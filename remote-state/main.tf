terraform {
    required_providers {
       aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
       }
    }

    backend "s3" {
        bucket= "omar-chaalan-terraform-state"
        key = "remote-state/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-state-lock"
        encrypt = true
    }
}

provider "aws" {
     region = "us-east-1"

     default_tags {
        tags = {
            Owner = "omar"
            ManagedBy = "terraform"
        }
     }
}

resource "aws_vpc" "my_second_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "my_second_vpc_updated"
    }
}

resource "aws_subnet" "public_subnet1" {
    vpc_id = aws_vpc.my_second_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "public_subnet1"
    }

}

resource "aws_subnet" "private_subnet1" {
    vpc_id = aws_vpc.my_second_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = false

    tags = {
        Name = "private_subnet1"
    }
}


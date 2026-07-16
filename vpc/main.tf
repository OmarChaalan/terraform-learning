terraform {
    required_providers {
       aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
       }
    }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "my_first_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "my-first-terraform-vpc"
        Environment = "prod"
        Owner = "omar"
    }
}

resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.my_first_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "public-subnet-1"
        Environment = "prod"
        Owner = "omar"
    }
}

resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.my_first_vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "private-subnet-1"
        Environment = "prod"
        Owner = "omar"
    }
} 

resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.my_first_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true

    tags = {
        Name = "public-subnet-2"
        Environment = "prod"
        Owner = "omar"
    }
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.my_first_vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone= "us-east-1b"

    tags = {
        Name = "private-subnet-2"
        Environment = "prod"
        Owner = "omar"
    }
}
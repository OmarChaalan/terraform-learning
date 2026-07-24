terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }

    backend "s3" {
        bucket = "omar-chaalan-terraform-state"
        key = "production-vpc/terraform.tfstate"
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

resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = var.enable_dns
    enable_dns_support = var.enable_dns
    
    tags = {
        Name = "${local.name_prefix}-vpc"
    }
}

resource "aws_internet_gateway" "main-igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${local.name_prefix}-igw"
    }
}

resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
        Name = "${local.name_prefix}-nat-eip"
    }
}

resource "aws_nat_gateway" "main-ngw" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public_subnet_1.id

    tags = {
        Name = "${local.name_prefix}-nat"
    }

    depends_on = [ aws_internet_gateway.main-igw ]
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main-igw.id
    }

    tags = {
        Name = "${local.name_prefix}-public-rt"
    }
}

resource "aws_route_table_association" "public_rt_association_1" {
    subnet_id = aws_subnet.public_subnet_1.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_association_2" {
    subnet_id = aws_subnet.public_subnet_2.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main-ngw.id
    }

    tags = {
        Name = "${local.name_prefix}-private-rt"
    }
}

resource "aws_route_table_association" "private_rt_association_1" {
    subnet_id = aws_subnet.private_subnet_1.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_association_2" {
    subnet_id = aws_subnet.private_subnet_2.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnets_cidrs[0]
    availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true

    tags = {
        Name = "${local.name_prefix}-public-subnet-1"
    }
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnets_cidrs[1]
    availability_zone = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = true

    tags = {
        Name = "${local.name_prefix}-public-subnet-2"
    }
}

resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnets_cidrs[0]
    availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = false

    tags = {
        Name = "${local.name_prefix}-private-subnet-1"
    }
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnets_cidrs[1]
    availability_zone = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = false
    
    tags = {
        Name = "${local.name_prefix}-private-subnet-2"
    }
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

resource "aws_security_group" "web_sg" {
    vpc_id = aws_vpc.main.id

    ingress {
        description = "Allow HTTP from anywhere"
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow HTTPs from anywehre"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow SSH ONLY from my IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    egress {
        description = "Allow outbound to everywhere"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${local.name_prefix}-web-sg"
        Description = "Allow HTTP and HTTPS"
    }
}

resource "aws_security_group" "private_sg" {
    vpc_id = aws_vpc.main.id

    ingress {
        description = "Allow traffic from web servers only"
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = [aws_security_group.web_sg.id]
    }

    egress {
        description = "Allow outbound to anywhere"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${local.name_prefix}-private-sg"
        Description = "Allow traffic only from web_sg, NO direct internet access"
    }
}
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }

    backend "s3" {
        bucket = "omar-chaalan-terraform-state"
        key = "ec2-basics/terraform.tfstate"
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

data "aws_availability_zones" "available" {
    state = "available"
}

resource "aws_vpc" "main" {
    cidr_block = var.cidr_block
    enable_dns_hostnames = var.enable_dns
    enable_dns_support = var.enable_dns

    tags = {
        Name = "${local.name_prefix}-vpc"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${local.name_prefix}-igw"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.main.id
    map_public_ip_on_launch = true
    cidr_block = var.public_subnets_cidrs[0]
    availability_zone = data.aws_availability_zones.available.names[0]

    tags = {
        Name = "${local.name_prefix}-public-subnet-1"
    }
}

# GENERATE A NEW KEY: ssh-keygen -t rsa -b 4096 -f ~/.ssh/omar-terraform-key -N ""

resource "aws_key_pair" "deployer" {
    key_name = "${local.name_prefix}-key"
    public_key = file("~/.ssh/omar-terraform-key.pub")
}

resource "aws_security_group" "web_sg" {
    name = "${local.name_prefix}-web-sg"
    description = "Allow HTTP and SSH"
    vpc_id = aws_vpc.main.id

    ingress {
        description = "Allow HTTP from anywhere"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow SSH from my IP only"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    egress {
        description = "Allow all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${local.name_prefix}-web-sg"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "${local.name_prefix}-public-rt"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public.id
}

resource "aws_instance" "my_app_server" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    subnet_id = aws_subnet.public_subnet.id
    key_name = aws_key_pair.deployer.key_name

    user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
        environment = var.environment
    }))

    root_block_device {
      volume_size = 8
      volume_type = "gp3"
      delete_on_termination = true
    }

    tags = {
        Name = "${local.name_prefix}-ec2"
    }
}

## EXTRA EBS VOLUME STORAGE FOR THE EC2 (JUST FOR PRACTICE!)
resource "aws_ebs_volume" "extra_stroage" {
    availability_zone = data.aws_availability_zones.available.names[0]
    size = 5
    type = "gp3"

    tags = {
        Name = "${local.name_prefix}-extra-volume"
    }
}

## RECENTLY CREATED EBS VOLUME ATTACHMENT (JUST FOR PRACTICE!)
resource "aws_volume_attachment" "extra_stroage_attachment" {
    device_name = "/dev/sdh"
    volume_id = aws_ebs_volume.extra_stroage.id
    instance_id = aws_instance.my_app_server.id
}
terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "omar-chaalan-terraform-state"
    key = "multi-tier/terraform.tfstate"
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

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]

    filter {
      name = "name"
      values = [ "al2023-ami-*-x86_64" ]
    }

    filter {
      name = "virtualization-type"
      values = [ "hvm" ]
    }
}

data "aws_ssm_parameter" "db_password" {
    name = "/omar/dev/multi-tier-db-password"
}

resource "aws_instance" "app_server" {
    for_each = toset(var.availability_zones)
    
    ami = data.aws_ami.amazon_linux.id
    instance_type = var.instance_type
    subnet_id = module.vpc.public_subnet_ids[index(var.availability_zones, each.value)]
    vpc_security_group_ids = [module.vpc.web_sg_id]

    user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    environment = var.environment
  }))

  tags = {
    Name = "${local.name_prefix}-app-${each.value}"
  }
}

resource "aws_lb" "main" {
    name = "${local.name_prefix}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [ module.vpc.web_sg_id ]
    subnets = module.vpc.public_subnet_ids

    tags = {
      Name = "${local.name_prefix}-alb"
    }
}

resource "aws_lb_target_group" "app" {
    name = "${local.name_prefix}-tg"
    port = "80"
    protocol = "HTTP"
    vpc_id = module.vpc.vpc_id

    health_check {
      enabled = true
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 5
      interval = 30
      path = "/"
      matcher = "200"
    }

    tags = {
        Name = "${local.name_prefix}-tg"
    }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group_attachment" "app" {
  for_each = aws_instance.app_server
  target_group_arn = aws_lb_target_group.app.arn
  target_id = each.value.id
  port = 80
}

resource "aws_db_subnet_group" "main" {
  name = "${local.name_prefix}-db-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-db"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type = "gp3"
  storage_encrypted = true

  db_name = "appdb"
  username = "admin"
  password = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.vpc.private_sg_id]

  backup_retention_period = 0
  skip_final_snapshot = true

  tags = {
    Name = "${local.name_prefix}-db"
  }
}
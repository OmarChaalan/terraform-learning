terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "omar-chaalan-terraform-state"
    key = "security-practice/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}

provider "aws" {
    region = var.region

    default_tags {
      tags = "${local.common_tags}"
    }
}

data "aws_ssm_parameter" "db_password" {
    name = "/omar/dev/db_password"
}

resource "aws_s3_bucket" "app_data" {
    bucket = lower("${local.name_prefix}-app-data")
}

resource "aws_iam_policy" "s3_scoped_access" {
    name = "${local.name_prefix}-s3-scoped-access"
    description = "Least-privilege access to app_data bucket only"

    policy = jsonencode ({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = ["s3:GetObject", "s3:PutObject"]
                Resource = "${aws_s3_bucket.app_data.arn}/*"
            }
        ]
    })
}
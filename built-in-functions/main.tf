terraform {
    required_providers {
      source = "hasicorp/aws"
      version = "~> 5.0"
    }

    backend "s3" {
        bucket = "omar-chaalan-terraform-state"
        key = "built-in-functions/terraform.tfstate"
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

# merge() practice — combine common tags with a resource-specific one
resource "aws_s3_bucket" "practice" {
    bucket = lower("${local.name_prefix}-function-practice")

    tags = merge(local.common_tags , {
        Purpose = "practice"
    })
}

# lookup() practice — safe fallback if environment isn't in the map
resource "aws_s3_bucket" "sized_example" {
    bucket = lower("${local.name_prefix}-lookup-practice")

    tags = {
        Name = "lookup-practice"
        StorageTier = lookup(var.storage_tier_map, var.environment, "standard")
    }
}

resource "aws_s3_bucket" "purpose_buckets" {
    for_each = toset(var.bucket_purposes)

    bucket = lower("${local.name_prefix}-${each.value}-bucket")

    tags = {
        Name = "${local.name_prefix}-${each.value}-bucket"
        Purpose = each.value
    }
}

resource "aws_iam_policy" "s3_read_only" {
    name = "${local.name_prefix}-s3-read-only" 
    description = "Read-only access to the practice bucket"

    policy = jsonencode({
        version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = ["s3:GetObject", "s3:ListBucket"]
                Resource = [
                    aws_s3_bucket.practice.arn,
                    "${aws_s3_bucket.practice.arn}/*"
                ]
            }
        ]
    })
}
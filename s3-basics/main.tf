terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "omar-chaalan-terraform-state"
    key            = "s3-basics/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

resource "aws_s3_bucket" "app_data" {
  bucket = lower("${local.name_prefix}-app-data-omar-chaalan")
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSpecificRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::389813258685:role/github-actions-terraform-role"
        }
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.app_data.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "notes" {
  bucket = aws_s3_bucket.app_data.id
  key    = "notes.md"
  source = "${path.module}/notes.md"
  etag   = filemd5("${path.module}/notes.md")
}

/* 
For CloudFront - fetch data directly from an API on a different domain, CORS matters.
resource "aws_s3_bucket_cors_configuration" "app_data" {
    bucket = aws_s3_bucket.app_data.id

    cors_rule {
      allowed_headers = ["*"]
      allowed_methods = [ "GET", "HEAD" ]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
}
*/

output "bucket_name" {
  value = aws_s3_bucket.app_data.id
}

output "bucket_arn" {
  value = aws_s3_bucket.app_data.arn
}

output "versioning_status" {
  value = aws_s3_bucket_versioning.app_data.versioning_configuration[0].status
}
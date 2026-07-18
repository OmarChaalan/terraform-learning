output "practice_bucket_name" {
    value = aws_s3_bucket.practice.id
}

output "storage_tier_result" {
    description = "Result of the lookup() call"
    value = aws_s3_bucket.sized_example.tags["StorageTier"]
}
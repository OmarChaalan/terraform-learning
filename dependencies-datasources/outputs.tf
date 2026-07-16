output "available_azs" {
    description = "List of available AZs in this region"
    value = data.aws_availability_zones.available.names 
}

output "my_account_id" {
    description = "My current account ID"
    value = data.aws_caller_identity.current.account_id
}

output "my_user_arn" {
  description = "My current user ARN"
  value       = data.aws_caller_identity.current.arn
}
 
output "vpc_id" {
    description = "The ID of the VPC"
    value = aws_vpc.main.id
}

output "environment" {
    description = "The environment deployed to"
    value = var.environment
}

output "vpc_cidr" {
    description = "The CIDR block for the VPC"
    value = aws_vpc.main.cidr_block
}

output "public_subnets_cidrs" {
    description = "The CIDR blocks for the public subnets"
    value = [aws_subnet.public_subnet_1.cidr_block, aws_subnet.public_subnet_2.cidr_block]
}

output "private_subnet_cidrs" {
    description = "The CIDR blocks for the private subnets"
    value = [aws_subnet.private_subnet_1.cidr_block, aws_subnet.private_subnet_2.cidr_block]
}
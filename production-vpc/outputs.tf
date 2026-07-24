output "region" {
    description = "Which region used to deploy the resources"
    value = var.region
}

output "environment" {
    description = "What environment resources are deployed into"
    value = var.environment
}

output "vpc_id" {
    description = "VPC ID"
    value = aws_vpc.main.id
}

output "vpc_cidr" {
    description = "VPC CIDR block"
    value = aws_vpc.main.cidr_block
}

output "public_subnets_id" {
    description = "Public subnets ID"
    value = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "private_subnets_id" {
    description = "Private subnets ID"
    value = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "public_subnets_cidrs" {
    description = "Public subnets CIDR blocks"
    value = [aws_subnet.public_subnet_1.cidr_block, aws_subnet.public_subnet_2.cidr_block]
}

output "private_subnets_cidrs" {
    description = "Private subnets CIDR blocks"
    value = [aws_subnet.private_subnet_1.cidr_block, aws_subnet.private_subnet_2.cidr_block]
}
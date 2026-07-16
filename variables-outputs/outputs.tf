output "vpc_id" {
    description = "The ID of the VPC"
    value = aws_vpc.main.id
}

output "vpc_cidr" {
    description = "The CIDR block for the VPC"
    value = aws_vpc.main.cidr_block
}

output "public_subnets_ids" {
    description = "The IDs for the public subnets in the VPC"
    value = [aws_subnet.public-subnet-1, aws_subnet.public-subnet-2]
}

output "private_subnets_ids" {
    description = "The IDs for the private subnets in the VPC" 
    value = [aws_subnet.private-subnet-1, aws_subnet.private-subnet-2]
}

output "environment" {
    description = "The environment deployed to"
    value = var.environment
}
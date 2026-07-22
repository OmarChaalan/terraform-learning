output "environment" {
    description = "The environment deployed to"
    value = var.environment
}

output "vpc_id" {
    description = "The VPC ID" 
    value = aws_vpc.main.id
}

output "vpc_cidr" {
    description = "The CIDR block for the VPC"
    value = aws_vpc.main.cidr_block
}

output "public_subnet_cidr" {
    description = "The CIDR block for the public subnet"
    value = aws_subnet.public_subnet.cidr_block
} 

output "instance_public_ip" {
    description = "The public IP for the EC2"
    value = aws_instance.my_app_server.public_ip
}

output "instance_id" {
    description = "The Instance ID"
    value = aws_instance.my_app_server.id
}

output "ssh_command" {
    description = "Command to SSH into the instance"
    value = "ssh -i ~/.ssh/omar-terraform-key ec2-user@${aws_instance.my_app_server.public_ip}"
}
output "vpc_id" {
    value = aws_vpc.main.id
}

output "public_subnet_ids" {
    value = [for s in aws_subnet.public_subnet : s.id]
}

output "private_subnet_ids" {
    value = [for s in aws_subnet.private_subnet : s.id]
}

output "vpc_cidr" {
    value = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
    value = aws_internet_gateway.main_igw.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main_ngw.id
}

output "web_sg_id" {
  value = aws_security_group.web_sg.id
}

output "private_sg_id" {
  value = aws_security_group.private_sg.id
}

output "public_route_table_id" {
    value = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}
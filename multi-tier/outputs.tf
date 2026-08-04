output "alb_dns_name" {
    description = "The DNS name to access the load balancers"
    value = aws_lb.main.dns_name
}

output "db_endpoint" {
    value = aws_db_instance.main.endpoint
    sensitive = true
}
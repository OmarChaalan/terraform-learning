locals {
    ingress_rules = [
        { port = 80, description = "HTTP", cidr_blocks = ["0.0.0.0/0"]},
        { port = 443, description = "HTTPS", cidr_blocks = ["0.0.0.0/0"]},
        { port = 22, description = "SSH", cidr_blocks = [var.my_ip]}
    ]
}
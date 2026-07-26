resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = merge(var.common_tags, {
        Name = "${var.environment}-vpc"
    })
}

resource "aws_internet_gateway" "main_igw" {
    vpc_id = aws_vpc.main.id

    tags = merge(var.common_tags, {
        Name = "${var.environment}-igw"
    })
}

resource "aws_subnet" "public_subnet" {
    for_each = toset(var.availability_zones)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[index(var.availability_zones, each.value)]
    availability_zone = each.value
    map_public_ip_on_launch = true

    tags = merge(var.common_tags, {
        Name = "${var.environment}-public-subnet-${each.value}"
    })
}

resource "aws_subnet" "private_subnet" {
    for_each = toset(var.availability_zones)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[index(var.availability_zones, each.value)]
    availability_zone = each.value
    map_public_ip_on_launch = false

    tags = merge(var.common_tags, {
        Name = "${var.environment}-private-subnet-${each.value}"
    })
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_igw.id
    }

    tags = merge(var.common_tags, {
        Name = "${var.environment}-public-rt"
    })
}

resource "aws_route_table_association" "public_rt_association" {
    for_each = aws_subnet.public_subnet

    subnet_id = each.value.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat_eip" {
    domain = "vpc" 

    tags = merge(var.common_tags, {
        Name = "${var.environment}-nat-eip"
    })
}

resource "aws_nat_gateway" "main_ngw" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_subnet[var.availability_zones[0]].id

    tags = merge(var.common_tags, {
        Name = "${var.environment}-main-ngw"
    })

    depends_on = [aws_internet_gateway.main_igw]
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main_ngw.id
    }

    tags = merge(var.common_tags, {
        Name = "${var.environment}-private-rt"
    })
}

resource "aws_route_table_association" "private_rt_association" {
    for_each = aws_subnet.private_subnet

    subnet_id = each.value.id
    route_table_id = aws_route_table.private_rt.id
}


resource "aws_security_group" "web_sg" {
    vpc_id = aws_vpc.main.id
    name = "${var.environment}-web-sg"
    description = "Allow HTTP, HTTPS, and SSH from my IP"

    dynamic "ingress" {
        for_each = local.ingress_rules

        content {
            description = ingress.value.description
            from_port = ingress.value.port
            to_port = ingress.value.port
            protocol = "tcp"
            cidr_blocks = ingress.value.cidr_blocks
        }
    }

    egress {
        description = "Allow outbound to everywhere"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = merge(var.common_tags, {
        Name = "${var.environment}-web-sg"
    })
}

resource "aws_security_group" "private_sg" {
    vpc_id = aws_vpc.main.id
    name = "${var.environment}-private-sg"
    description = "Allow traffic only from web-sg"

    ingress {
        description = "Traffic only from web servers only"
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = [aws_security_group.web_sg.id]
    }

    egress {
        description = "Allow all outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    tags = merge(var.common_tags, {
        Name = "${var.environment}-private-sg"
    })
}
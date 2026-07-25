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

resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[0]
    availability_zone = var.availability_zones[0]
    map_public_ip_on_launch = true

    tags = merge(var.common_tags, {
        Name = "${var.environment}-public-subnet-1"
    })
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[1]
    availability_zone = var.availability_zones[1]
    map_public_ip_on_launch = true

    tags = merge(var.common_tags, {
        Name = "${var.environment}-public-subnet-2"
    })
}

resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[0]
    availability_zone = var.availability_zones[0]
    map_public_ip_on_launch = false

    tags = merge(var.common_tags, {
        Name = "${var.environment}-private-subnet-1"
    })
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[1]
    availability_zone = var.availability_zones[1]
    map_public_ip_on_launch = false

    tags = merge(var.common_tags, {
        Name = "${var.environment}-private-subnet-2"
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

resource "aws_route_table_association" "public_rt_association_1" {
    subnet_id = aws_subnet.public_subnet_1.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_association_2" {
    subnet_id = aws_subnet.public_subnet_2.id
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
    subnet_id = aws_subnet.public_subnet_1.id

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

resource "aws_route_table_association" "private_rt_association_1" {
    subnet_id = aws_subnet.private_subnet_1.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_association_2" {
    subnet_id = aws_subnet.private_subnet_2.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "web_sg" {
    vpc_id = aws_vpc.main.id
    name = "${var.environment}-web-sg"
    description = "Allow HTTP, HTTPS, and SSH from my IP"

    ingress {
        description = "HTTP from anywhere"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    ingress {
        description = "HTTPS from anywhere"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    ingress {
        description = "SSH only from IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ var.my_ip ]
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
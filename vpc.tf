resource "aws_vpc" "capstone_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "capstoneVPC"
  }
}

resource "aws_internet_gateway" "capstone_igw" {
  vpc_id = aws_vpc.capstone_vpc.id
  tags = {
    Name = "capstoneInternetGateway"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.capstone_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  count                   = length(var.public_subnet_cidrs)
  map_public_ip_on_launch = true
  tags = {
    Name = "capstonePublicSubnet-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.capstone_igw]
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.capstone_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  count             = length(var.private_subnet_cidrs)
  tags = {
    Name = "capstonePrivateSubnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.capstone_vpc.id
  tags = {
    Name = "capstoneRouteTable"
  }

  route {
    cidr_block = var.open_cidr
    gateway_id = aws_internet_gateway.capstone_igw.id
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# NAT Gateway Setup
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.capstone_igw]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "capstoneNatEIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet[0].id
  depends_on    = [aws_internet_gateway.capstone_igw]
  tags = {
    Name = "capstoneNatGateway"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.capstone_vpc.id
  tags = {
    Name = "privateRouteTable"
  }
  route {
    cidr_block     = var.open_cidr
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Groups
resource "aws_security_group" "sg_web_server" {
  name   = "webserver-sg"
  vpc_id = aws_vpc.capstone_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_alb" {
  name        = "applicationLoadBalancer-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.capstone_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.open_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All traffic
    cidr_blocks = [var.open_cidr]
  }

  tags = {
    Name = "applicationLoadBalancer-SecurityGroup"
  }
}

resource "aws_security_group" "sg_app_server" {
  name   = "app-server-sg"
  vpc_id = aws_vpc.capstone_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web_server.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

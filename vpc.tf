resource "aws_vpc" "capstone_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "capstoneVPC"
  }
}


resource "aws_subnet" "public_subnet_01" {
  vpc_id                  = aws_vpc.capstone_vpc.id
  cidr_block              = var.public_subnet_01_cidr
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true
  tags = {
    Name = "publicSubnet01"
  }
}

resource "aws_internet_gateway" "capstone_igw" {
  vpc_id = aws_vpc.capstone_vpc.id
  tags = {
    Name = "capstoneInternetGateway"
  }
}
resource "aws_route_table" "capstone_route_table" {
  vpc_id = aws_vpc.capstone_vpc.id
  tags = {
    Name = "capstoneRouteTable"
  }
}
resource "aws_route" "capstone_route" {
  route_table_id         = aws_route_table.capstone_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.capstone_igw.id
}
resource "aws_route_table_association" "capstone_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_01.id
  route_table_id = aws_route_table.capstone_route_table.id
}
resource "aws_security_group" "capstone_sg" {
  name        = "capstoneSecurityGroup"
  description = "Security group for the capstone project"
  vpc_id      = aws_vpc.capstone_vpc.id

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
    cidr_blocks = [var.open_cidr]

  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.open_cidr]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "capstoneSecurityGroup"
  }
}


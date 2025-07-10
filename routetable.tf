resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.capstone_vpc.id
  tags = {
    Name = "capstoneRouteTable"
  }

  route {
    cidr_block = var.anywhere_ipv4
    gateway_id = aws_internet_gateway.capstone_igw.id
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.capstone_vpc.id
  tags = {
    Name = "privateRouteTable"
  }
  route {
    cidr_block     = var.anywhere_ipv4
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
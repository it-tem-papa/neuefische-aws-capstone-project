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
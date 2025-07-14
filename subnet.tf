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

resource "aws_db_subnet_group" "wordpress_subnet_group" {
  name       = "wordpress-subnet-group"
  subnet_ids = aws_subnet.private_subnet[*].id
  tags = {
    Name = "wordpress-subnet-group"
  }

  depends_on = [aws_vpc.capstone_vpc]

}
resource "aws_vpc" "capstone_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true   # This is required
  enable_dns_hostnames = true   # This is required for public RDS access
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
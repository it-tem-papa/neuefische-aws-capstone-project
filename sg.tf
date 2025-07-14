# Web Server Security Group (for bastion host in public subnet)
resource "aws_security_group" "sg_web_server" {
  name        = "web-server-sg"
  vpc_id      = aws_vpc.capstone_vpc.id
  description = "Security group for web server (bastion host)"

  tags = {
    Name = "web-server-security-group"
  }
}

# Web Server - SSH from your IP only
resource "aws_vpc_security_group_ingress_rule" "web_ssh_rule" {
  security_group_id = aws_security_group.sg_web_server.id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "Allow SSH access from your IP"
}

# Web Server - HTTP from anywhere (for management/testing)
resource "aws_vpc_security_group_ingress_rule" "web_http_rule" {
  security_group_id = aws_security_group.sg_web_server.id
  cidr_ipv4         = var.anywhere_ipv4
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "Allow HTTP access for management"
}

# Web Server - All outbound traffic
resource "aws_vpc_security_group_egress_rule" "web_outbound_rule" {
  security_group_id = aws_security_group.sg_web_server.id
  cidr_ipv4         = var.anywhere_ipv4
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic from web server"
}

# ALB Security Group
resource "aws_security_group" "sg_alb" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.capstone_vpc.id
  description = "Security group for Application Load Balancer"

  tags = {
    Name = "alb-security-group"
  }
}

# ALB Inbound Rule - HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "alb_http_rule" {
  security_group_id = aws_security_group.sg_alb.id
  cidr_ipv4         = var.anywhere_ipv4
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "Allow HTTP access to ALB"
}

# ALB Outbound Rule - HTTP to app servers only
resource "aws_vpc_security_group_egress_rule" "alb_outbound_rule" {
  security_group_id            = aws_security_group.sg_alb.id
  referenced_security_group_id = aws_security_group.sg_app_server.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
  description                  = "Allow HTTP to app servers only"
}

# App Server Security Group (for private instances)
resource "aws_security_group" "sg_app_server" {
  name        = "app-server-sg"
  vpc_id      = aws_vpc.capstone_vpc.id
  description = "Security group for app servers in private subnets"

  tags = {
    Name = "app-server-security-group"
  }
}

# App Server - HTTP from ALB only
resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id            = aws_security_group.sg_app_server.id
  referenced_security_group_id = aws_security_group.sg_alb.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
  description                  = "Allow HTTP from ALB only"
}

# App Server - SSH from web server only
resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_web" {
  security_group_id            = aws_security_group.sg_app_server.id
  referenced_security_group_id = aws_security_group.sg_web_server.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  description                  = "Allow SSH from web server only"
}

# App Server - All outbound traffic
resource "aws_vpc_security_group_egress_rule" "app_outbound_rule" {
  security_group_id = aws_security_group.sg_app_server.id
  cidr_ipv4         = var.anywhere_ipv4
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic from app servers"
}

# Database Security Group (for RDS instances)
resource "aws_security_group" "sg_db" {
  name        = "db-sg"
  vpc_id      = aws_vpc.capstone_vpc.id
  description = "Security group for RDS instances"
  tags = {
    Name = "db-security-group"
  }
}

# Database - MySQL from app servers only
resource "aws_vpc_security_group_ingress_rule" "db_mysql_from_app" {
  security_group_id            = aws_security_group.sg_db.id
  referenced_security_group_id = aws_security_group.sg_app_server.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
  description                  = "Allow MySQL access from app servers only"
}

# Database - All outbound traffic
resource "aws_vpc_security_group_egress_rule" "db_outbound_rule" {
  security_group_id = aws_security_group.sg_db.id
  cidr_ipv4         = var.anywhere_ipv4
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic from database"
}
# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  availability_zone           = var.availability_zones[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_web_server.id]
  subnet_id                   = aws_subnet.public_subnet[0].id
  user_data                   = file("${path.module}/scripts/userdata_web.sh")

  tags = {
    Name = "webServer"
  }
}


# For test porposes
# # Commenting out the Web Server Instances 
# # These instances are not required, since we are using Auto Scaling Group

# # Create Web Server Instance in Public Subnet 1
# resource "aws_instance" "web" {
#   ami                    = data.aws_ami.amazon_linux_2.id
#   instance_type          = var.instance_type
#   availability_zone      = var.availability_zones[0]
#   vpc_security_group_ids = [aws_security_group.sg_web_server.id]
#   subnet_id              = aws_subnet.public_subnet[0].id
#   key_name               = "vockey" # Create new key if using different region than us-west-2
#   user_data              = file("${path.module}/scripts/loadbalancertest.sh")
#   tags = {
#     Name = "AwsCapstoneWebServer"
#   }
# }

# # Second Instance for Load Balancing testing -- Will be replaced by Auto Scaling Group
# resource "aws_instance" "web2" {
#   ami                    = data.aws_ami.amazon_linux_2.id
#   instance_type          = var.instance_type
#   availability_zone      = var.availability_zones[1]
#   vpc_security_group_ids = [aws_security_group.sg_web_server.id]
#   subnet_id              = aws_subnet.public_subnet[1].id
#   key_name               = "vockey" # Create new key if using different region than us-west-2
#   user_data              = file("${path.module}/scripts/loadbalancertest.sh")
#   tags = {
#     Name = "AwsCapstoneWebServer2"
#   }
# }
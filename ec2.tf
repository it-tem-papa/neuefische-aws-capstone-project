resource "aws_instance" "web_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  availability_zone           = var.availability_zone_a
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.capstone_sg.id]
  subnet_id                   = aws_subnet.public_subnet_01.id
  user_data                   = file("${path.module}/scripts/userdata.sh")

  tags = {
    Name = "webServer"
  }
}
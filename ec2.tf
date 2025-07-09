resource "aws_instance" "web_server" {
  ami                         = var.ami_id
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

# Launch Template for App Server
resource "aws_launch_template" "app_template" {
  name_prefix   = "appServerTemplate-Wordpress"
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data = filebase64("${path.module}/scripts/userdata_app.sh")

  network_interfaces {
    security_groups             = [aws_security_group.sg_app_server.id]
    associate_public_ip_address = false
  }

  tags = {
    Name = "appTemplate-Wordpress"
  }
}


# Auto Scaling Group for App Server
resource "aws_autoscaling_group" "asg_app" {
  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.private_subnet[*].id
  health_check_type   = "EC2"
  health_check_grace_period = 300   # Wait 5 minutes before checking if a new server is healthy
  force_delete              = true  # Force delete the ASG when destroyed
  wait_for_capacity_timeout   = "0" # Do not wait for capacity to be reached
}

# Load Balancer and Target Group
resource "aws_lb" "lb_app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = aws_subnet.public_subnet[*].id
}

resource "aws_lb_target_group" "tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.capstone_vpc.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb_app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_autoscaling_attachment" "app_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg_app.name
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}
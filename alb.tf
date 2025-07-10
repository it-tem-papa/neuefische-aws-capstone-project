# Application Load Balancer
resource "aws_lb" "lb_app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = aws_subnet.public_subnet[*].id

  enable_deletion_protection = false

  tags = {
    Name = "app-load-balancer"
    Type = "Application"
  }
}

# Target Group for the Application Load Balancer
resource "aws_lb_target_group" "tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.capstone_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-399"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "app-target-group"
  }
}

# Listener for the Application Load Balancer
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb_app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}


# For test porposes, you can attach existing EC2 instances to the target group.
# Target Group Attachment
# Need to be used if not using Auto Scaling Group
# resource "aws_lb_target_group_attachment" "capstone_attachment" {
#   target_group_arn = aws_lb_target_group.tg.arn
#   target_id        = aws_instance.web.id
#   port             = 80
# }

# resource "aws_lb_target_group_attachment" "capstone_attachment2" {
#   target_group_arn = aws_lb_target_group.tg.arn
#   target_id        = aws_instance.web2.id
#   port             = 80
# }
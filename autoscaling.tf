# Launch Template for App Server
resource "aws_launch_template" "app_template" {
  name_prefix   = "template-Wordpress"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data = base64encode(templatefile("${path.module}/scripts/userdata_app.sh", {
    db_address   = aws_db_instance.db_wordpress.address
    db_port      = aws_db_instance.db_wordpress.port
    db_name      = aws_db_instance.db_wordpress.db_name
    db_username  = aws_db_instance.db_wordpress.username
    db_password  = aws_db_instance.db_wordpress.password
    alb_dns_name = aws_lb.lb_app.dns_name
  }))

  network_interfaces {
    security_groups             = [aws_security_group.sg_app_server.id]
    associate_public_ip_address = false
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "template-WordPress"
      Type = "Application"
    }
  }

  tags = {
    Name = "template-Wordpress"
  }
}

# Auto Scaling Group for App Server
resource "aws_autoscaling_group" "asg_app" {
  name = "asg-app-servers"
  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }
  min_size                  = 1
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = aws_subnet.private_subnet[*].id
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true
  wait_for_capacity_timeout = "0"

  tag {
    key                 = "Name"
    value               = "ASG-AppServers"
    propagate_at_launch = false
  }
}

# Auto Scaling attachment to connect ASG with ALB Target Group
resource "aws_autoscaling_attachment" "app_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg_app.name
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg_app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg_app.name
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-utilization-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_app.name
  }
}
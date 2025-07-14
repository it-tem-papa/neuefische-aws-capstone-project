resource "aws_db_instance" "db_wordpress" {
  identifier             = "wordpress-db"
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  storage_type           = "gp2"
  db_name                = "wordpress"
  username               = var.DB_USERNAME
  password               = var.DB_PASSWORD
  multi_az               = false
  skip_final_snapshot    = true
  publicly_accessible    = true // Set to false for production
  vpc_security_group_ids = [aws_security_group.sg_db.id]
  db_subnet_group_name   = aws_db_subnet_group.wordpress_subnet_group.name

  tags = {
    Name = "wordpress-db-instance"
  }

}

# Output the RDS connection details
output "rds_endpoint" {
  value = aws_db_instance.db_wordpress.endpoint
}

output "rds_port" {
  value = aws_db_instance.db_wordpress.port
}

output "database_name" {
  value = aws_db_instance.db_wordpress.db_name
}
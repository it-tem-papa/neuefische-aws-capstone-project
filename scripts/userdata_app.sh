#!/bin/bash

sudo yum update -y
sudo amazon-linux-extras enable php8.0
sudo amazon-linux-extras enable mariadb10.5
sudo yum install -y httpd php php-mysqlnd php-fpm php-json php-mbstring unzip wget

# Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

sudo yum install -y mysql

slepp 10

# Download and configure WordPress
cd /var/www/html
wget https://wordpress.org/latest.zip
unzip latest.zip
cp -r wordpress/* .
rm -rf wordpress latest.zip


sed -i "s/database_name_here/${db_name}/" wp-config-sample.php
sed -i "s/username_here/${db_username}/" wp-config-sample.php
sed -i "s/password_here/${db_password}/" wp-config-sample.php
sed -i "s/localhost/${db_address}/" wp-config-sample.php

mv wp-config-sample.php wp-config.php
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Create DB user on RDS
mysql -h ${db_address} -P ${db_port} -u ${db_username} -p${db_password} <<SQL
CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON ${db_name}.* TO 'wpuser'@'%';
FLUSH PRIVILEGES;
SQL

# Restart Apache
sudo systemctl restart httpd
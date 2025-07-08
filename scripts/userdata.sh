#!/bin/bash

sudo yum update -y
amazon-linux-extras enable php8.0
# Install Apache and PHP
yum install -y httpd php php-mysqlnd php-fpm php-json php-mbstring unzip wget

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Install MariaDB server
yum install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb


# TODO testen ob db über http://<EC2-PUBLIC-IP>/phpmyadmin erreichen kann
# cd /var/www/html
# wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
# tar -xvzf phpMyAdmin-latest-all-languages.tar.gz
# mv phpMyAdmin-*-all-languages phpmyadmin
# rm phpMyAdmin-latest-all-languages.tar.gz

# chown -R apache:apache /var/www/html/phpmyadmin

# Secure MariaDB installation
mysql -e "CREATE DATABASE wordpress;"
mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Download and configure WordPress
cd /var/www/html
wget https://wordpress.org/latest.zip
unzip latest.zip
cp -r wordpress/* .
rm -rf wordpress latest.zip


# Configure wp-config.php
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/wordpress/" wp-config.php
sed -i "s/username_here/wpuser/" wp-config.php
sed -i "s/password_here/wppassword/" wp-config.php


# Set permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Restart Apache
systemctl restart httpd


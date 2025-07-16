#!/bin/bash

# === CONFIGURATION ===
GIT_REPO="https://github.com/it-tem-papa/neuefische-aws-capstone-project-wordpress.git"
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
DB_ADDRESS=${db_address}
DB_PORT=${db_port}
LIVE_URL="http://${alb_dns_name}" # This will be replaced by the actual ALB DNS name
LOCAL_URL='http://localhost:8080'

echo "This is the live URL: $LIVE_URL"

sudo yum update -y
sudo amazon-linux-extras enable php8.0
sudo amazon-linux-extras enable mariadb10.5
sudo yum install -y httpd php php-mysqlnd php-fpm php-json php-mbstring tar git

# Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# Enable mod_rewrite for WordPress permalinks
echo "LoadModule rewrite_module modules/mod_rewrite.so" | sudo tee -a /etc/httpd/conf/httpd.conf

# Configure Apache to allow .htaccess overrides
sudo tee /etc/httpd/conf.d/wordpress.conf <<EOF
<Directory "/var/www/html">
    AllowOverride All
    Require all granted
</Directory>
EOF

sudo yum install -y mysql

sleep 10


# === CLONE THE REPOSITORY ===
cd /tmp
git clone "$GIT_REPO"
cd neuefische-aws-capstone-project-wordpress

rm -rf .github

# === EXTRACT WORDPRESS FILES ===
echo "Checking if wordpress-files.tar.gz exists..."
ls -la wordpress/wordpress-files.tar.gz || echo "wordpress-files.tar.gz not found!"

mkdir /tmp/wordpress-unpacked
echo "Extracting WordPress files..."
tar -xzf wordpress/wordpress-files.tar.gz -C /tmp/wordpress-unpacked
echo "Contents of unpacked directory:"
ls -la /tmp/wordpress-unpacked/

# === COPY WORDPRESS TO APACHE WEB ROOT ===
echo "Copying WordPress files to web root..."
sudo rm -rf /var/www/html/*
sudo cp -r /tmp/wordpress-unpacked/* /var/www/html/
echo "Contents of web root after copy:"
sudo ls -la /var/www/html/

# === SET PERMISSIONS ===
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www/html

# === CREATE .HTACCESS FOR WORDPRESS ===
sudo tee /var/www/html/.htaccess <<EOF
# BEGIN WordPress
RewriteEngine On
RewriteRule ^index\.php$ - [L]
RewriteCond %%{REQUEST_FILENAME} !-f
RewriteCond %%{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
# END WordPress
EOF
sudo chown apache:apache /var/www/html/.htaccess

# === CREATE WORDPRESS DATABASE ===
mysql -h "$DB_ADDRESS" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" <<EOF
CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO 'wpuser'@'%';
FLUSH PRIVILEGES;
EOF

# === IMPORT DATABASE DUMP TO RDS ===
echo "Current directory: $(pwd)"
echo "Looking for wordpress.sql file..."
ls -la wordpress.sql 2>/dev/null || echo "wordpress.sql not found in current directory"

if [ -f "./wordpress.sql" ]; then
    echo "Found wordpress.sql, importing database..."
    mysql -h "$DB_ADDRESS" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < ./wordpress.sql
    if [ $? -eq 0 ]; then
        echo "Database import successful. Checking if tables exist..."
        # Check if wp_options table exists
        TABLE_COUNT=$(mysql -h "$DB_ADDRESS" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES LIKE 'wp_options';" | wc -l)
        if [ $TABLE_COUNT -gt 1 ]; then
            echo "WordPress tables found. Updating URLs..."
            # Update siteurl and home URL after import
            mysql -h "$DB_ADDRESS" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" <<EOF
            UPDATE wp_options SET option_value = "$LIVE_URL" WHERE option_name IN ('siteurl', 'home');
            UPDATE wp_posts SET guid = REPLACE(guid, "$LOCAL_URL", "$LIVE_URL");
            UPDATE wp_posts SET post_content = REPLACE(post_content, "$LOCAL_URL", "$LIVE_URL");
EOF
            echo "URL updates completed."
        else
            echo "WordPress tables not found after import. The SQL file might be empty or invalid."
        fi
    else
        echo "Database import failed!"
    fi
else
    echo "Database dump file not found. Skipping import."
fi
# === CONFIGURE WORDPRESS ===
cd /var/www/html
if [ -f wp-config-sample.php ]; then
    sudo cp wp-config-sample.php wp-config.php
    sudo sed -i "s/database_name_here/$DB_NAME/" wp-config.php
    sudo sed -i "s/username_here/$DB_USER/" wp-config.php
    sudo sed -i "s/password_here/$DB_PASSWORD/" wp-config.php
    sudo sed -i "s/localhost/$DB_ADDRESS/" wp-config.php
fi

# Restart Apache
sudo systemctl restart httpd
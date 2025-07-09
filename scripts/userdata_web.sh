  #!/bin/bash
sudo yum update -y
sudo yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Webserver up and running" > /var/www/html/index.html
EOF
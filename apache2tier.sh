
 #!/bin/bash
 # Enable debugging and logging
exec > /var/log/user-data.log 2>&1
set -x

# Update package lists and install Apache
yum update -y
yum install -y httpd

# Start Apache service and enable it to start on boot
systemctl start httpd
systemctl enable httpd

# Create a simple test page
echo "<h1>Apache Web Server is Running on EC2</h1>" > /var/www/html/index.html

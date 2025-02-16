
 #!/bin/bash
# Update package lists and install Apache
sudo yum update -y
sudo yum install -y httpd

# Start Apache service and enable it to start on boot
sudo systemctl start httpd
sudo systemctl enable httpd

# Create a simple test page
echo "<h1>Apache Web Server is Running on EC2</h1>" > /var/www/html/index.html

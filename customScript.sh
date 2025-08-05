#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl enable apache2
sudo systemctl start apache2

# Ensure directory exists before writing the HTML file
sudo mkdir -p /var/www/html
echo "<html><body><h1>Welcome to your Azure VM!</h1></body></html>" | sudo tee /var/www/html/index.html

sudo systemctl restart apache2

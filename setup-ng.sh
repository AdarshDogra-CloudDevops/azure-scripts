#!/bin/bash

echo "✅ Starting VM bootstrap..."

# Install NGINX
sudo apt-get update -y
sudo apt-get install -y nginx

# Detect hostname (VM name)
VM_NAME=$(hostname)

# Create a unique index.html
echo "<h1>This is $VM_NAME</h1>" | sudo tee /var/www/html/index.html

# Start and enable nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "✅ Setup complete for $VM_NAME"

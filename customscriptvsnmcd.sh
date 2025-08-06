#!/bin/bash

echo "=== Starting Ubuntu VM setup script with GUI ==="

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root. Use: sudo ./vm-setup.sh"
  exit 1
fi

# Update package list
echo "🔄 Updating apt packages..."
apt-get update -y

#install unzip
echo "🔧 Installing unzip utility..."
apt-get install -y unzip

#install at
echo "🔧 Installing at utility..."
apt-get install -y at
systemctl enable --now atd

# Install VS Code
echo "🧠 Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  > /etc/apt/sources.list.d/vscode.list
apt-get update -y
apt-get install -y code

# install chromium browser
echo "🌐 Installing Chromium browser..."
apt-get install -y chromium-browser || apt-get install -y chromium

#install docker
echo "🐳 Installing Docker..."
apt-get install -y docker.io

# Enable Docker service
systemctl enable docker
systemctl start docker

#install network miner
echo "🔍 Installing Network Miner..."   
wget -q https://download.netresec.com/networkminer/NetworkMiner_3-0.zip -O /tmp/networkminer.zip
unzip /tmp/networkminer.zip -d /opt/networkminer
chmod +x /opt/networkminer/NetworkMiner.exe

echo "🕒 Scheduling auto-shutdown in 5 minutes..."
echo "shutdown -h now" | at now + 5 minutes


#!/bin/bash

echo "=== Starting Ubuntu VM setup script "

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root. Use: sudo ./vm-setup.sh"
  exit 1
fi

# Non-interactive frontend
export DEBIAN_FRONTEND=noninteractive

# Use Azure mirror (more stable on Azure VMs)
sed -i 's|http://archive.ubuntu.com|http://azure.archive.ubuntu.com|g' /etc/apt/sources.list
apt-get clean
apt-get update -y

# install unzip
echo "🔧 Installing unzip utility..."
apt-get install -y unzip

# install at
echo "🔧 Installing at utility..."
apt-get install -y at || true
systemctl enable --now atd || true

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

# install docker
echo "🐳 Installing Docker..."
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# install network miner
echo "🔍 Installing Network Miner..."   
wget -q https://download.netresec.com/networkminer/NetworkMiner_3-0.zip -O /tmp/networkminer.zip
unzip /tmp/networkminer.zip -d /opt/networkminer
chmod +x /opt/networkminer/NetworkMiner_3-0/NetworkMiner.exe || true

# auto shutdown in 5 mins
echo "🕒 Scheduling auto-shutdown in 5 minutes..."
echo "shutdown -h now" | at now + 5 minutes || echo "⚠️ Failed to schedule shutdown"

#!/bin/bash

echo "=== Starting Ubuntu VM setup script with GUI ==="

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root. Use: sudo ./vm-setup.sh"
  exit 1
fi

# Disable UFW (firewall)
echo "🔧 Disabling UFW firewall..."
ufw disable

# Update package list
echo "🔄 Updating apt packages..."
apt-get update -y

# Install GUI (Xfce) and xrdp
echo "🖥️ Installing Xfce Desktop Environment and xrdp..."
apt-get install -y xfce4 xfce4-goodies xrdp

# Set default desktop environment
echo "xfce4-session" > /home/azureadmin/.xsession
chown azureadmin:azureadmin /home/azureadmin/.xsession

# Enable xrdp and add user to ssl-cert group
systemctl enable xrdp
adduser xrdp ssl-cert
systemctl restart xrdp

# Install Google Chrome
echo "🌐 Installing Google Chrome..."
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
apt-get install -y /tmp/chrome.deb || apt --fix-broken install -y

# Install VS Code
echo "🧠 Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  > /etc/apt/sources.list.d/vscode.list
apt-get update -y
apt-get install -y code

# Create Desktop shortcuts
echo "📁 Creating desktop shortcuts..."
DESKTOP_PATH="/home/azureadmin/Desktop"
mkdir -p "$DESKTOP_PATH"

# Azure Portal shortcut
echo "[Desktop Entry]
Name=Azure Portal
Exec=/usr/bin/google-chrome-stable https://portal.azure.com
Icon=google-chrome
Type=Application
Categories=Network;" > "$DESKTOP_PATH/AzurePortal.desktop"

# Google Chrome shortcut
cp /usr/share/applications/google-chrome.desktop "$DESKTOP_PATH/"
chmod +x "$DESKTOP_PATH/google-chrome.desktop"

# VS Code shortcut
cp /usr/share/applications/code.desktop "$DESKTOP_PATH/"
chmod +x "$DESKTOP_PATH/code.desktop"

# Create VMDetails.txt
echo "👤 Writing VM credentials to VMDetails.txt..."
echo "Username: azureadmin" > "$DESKTOP_PATH/VMDetails.txt"
echo "Password: P@ssword1234!" >> "$DESKTOP_PATH/VMDetails.txt"

# Set ownership
chown -R azureadmin:azureadmin "$DESKTOP_PATH"

echo "✅ Ubuntu GUI setup complete. Connect via RDP on port 3389. Chrome, VS Code, and shortcuts created."

#!/bin/bash
# customscript_kali_gui.sh
# Installs Google Chrome + GUI (XFCE) + XRDP on Kali Linux VM
# Usage: bash customscript_kali_gui.sh <adminUsername>

set -e

ADMIN_USER=$1

# ----------------------------
# Fix Kali repo GPG key issue
# ----------------------------
sudo mkdir -p /etc/apt/trusted.gpg.d
wget -q -O - https://archive.kali.org/archive-key.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg > /dev/null

# ----------------------------
# Update system
# ----------------------------
sudo apt-get update -y
sudo apt-get upgrade -y

# ----------------------------
# Install dependencies
# ----------------------------
sudo apt-get install -y wget curl gnupg2 apt-transport-https software-properties-common

# ----------------------------
# Install Google Chrome
# ----------------------------
# Add Google repo key (modern method, no apt-key)
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/google-chrome.gpg

# Add Google Chrome repository
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

# Update again for Chrome repo
sudo apt-get update -y

# Install Chrome
sudo apt-get install -y google-chrome-stable

# ----------------------------
# Install GUI (XFCE) + XRDP
# ----------------------------
sudo apt-get install -y xfce4 xfce4-goodies xrdp

# Enable and start XRDP service
sudo systemctl enable xrdp
sudo systemctl start xrdp

# ----------------------------
# Desktop shortcut for Chrome
# ----------------------------
DESKTOP_PATH="/home/$ADMIN_USER/Desktop"
mkdir -p "$DESKTOP_PATH"

cp /usr/share/applications/google-chrome.desktop "$DESKTOP_PATH/"
chmod +x "$DESKTOP_PATH/google-chrome.desktop"
chown $ADMIN_USER:$ADMIN_USER "$DESKTOP_PATH/google-chrome.desktop"

# ----------------------------
# Verify installation
# ----------------------------
google-chrome --version || echo "Chrome installation failed"
echo "✅ XFCE + XRDP + Chrome installation complete"

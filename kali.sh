#!/bin/bash
# customscript_kali_gui.sh
set -e

ADMIN_USER=$1

# ----------------------------
# Update and install keyring package first
# ----------------------------
sudo apt-get update -y
sudo apt-get install -y kali-archive-keyring wget curl gnupg2 apt-transport-https software-properties-common

# ----------------------------
# Update system
# ----------------------------
sudo apt-get update -y
sudo apt-get upgrade -y

# ----------------------------
# Install Google Chrome
# ----------------------------
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/google-chrome.gpg
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt-get update -y
sudo apt-get install -y google-chrome-stable

# ----------------------------
# Install GUI (XFCE) + XRDP
# ----------------------------
sudo apt-get install -y xfce4 xfce4-goodies xrdp
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

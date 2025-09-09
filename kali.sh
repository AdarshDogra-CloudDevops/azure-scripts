#!/bin/bash
# customscript_kali_gui.sh
# This script installs Google Chrome + GUI (XFCE) + XRDP on Kali Linux VM

set -e

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
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
# Install XFCE desktop environment
sudo apt-get install -y kali-desktop-xfce

# Install xrdp for remote desktop access
sudo apt-get install -y xrdp

# Enable and start XRDP service
sudo systemctl enable xrdp
sudo systemctl start xrdp

# ----------------------------
# Verify installation
# ----------------------------
google-chrome --version || echo "Chrome installation failed"
echo "XFCE and XRDP installation complete"

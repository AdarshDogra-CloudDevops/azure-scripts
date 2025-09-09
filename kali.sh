#!/bin/bash
# customscriptnerou.sh
# This script installs Google Chrome on Kali Linux VM

set -e

# Update system
sudo apt-get update -y

# Install dependencies
sudo apt-get install -y wget curl gnupg2 apt-transport-https software-properties-common

# Add Google Chrome repo key (modern way, no apt-key)
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/google-chrome.gpg

# Add Google Chrome repository
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

# Update package lists again
sudo apt-get update -y

# Install Google Chrome stable
sudo apt-get install -y google-chrome-stable

# Verify installation
google-chrome --version || echo "Chrome installation failed"

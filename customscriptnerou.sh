#!/bin/bash 
echo "=== Starting Ubuntu VM setup script "

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root. Use: sudo ./vm-setup.sh"
  exit 1
fi

USERNAME="adarsh"
PASSWORD="Intern@12345"

# Create the user without prompts
sudo useradd -m -s /bin/bash "$USERNAME"

# Set the user password non-interactively
echo "${USERNAME}:${PASSWORD}" | sudo chpasswd

# Add to sudo group (optional)
sudo usermod -aG sudo "$USERNAME"
echo "✅ User $USERNAME created and added to sudo group."

# Disable root SSH login
sudo sed -i '/^#\?PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "✅ Disabled SSH login for root."

# Restart SSH service to apply root login change
sudo systemctl restart sshd
echo "🔄 SSH service restarted to apply changes."

# Lock root account
passwd -l root
echo "✅ Root account locked from login."

# sudo commands will work without password prompts
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
chmod 0440 "/etc/sudoers.d/$USERNAME"


sudo -i -u "$USERNAME" bash <<'EOF'
echo "=== Running installation as: $(whoami) ==="               

# Update package list
echo "🔄 Updating apt packages..."
sudo apt-get update -y

# Install GUI (Xfce) and xrdp
echo "🖥️ Installing Xfce Desktop Environment and xrdp..."
sudo apt-get install -y xfce4 xfce4-goodies xrdp

# Set default desktop environment for adarsh
echo "xfce4-session" > ~/.xsession

# Enable xrdp and add user to ssl-cert group
sudo systemctl enable xrdp
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp

# install unzip
echo "🔧 Installing unzip utility..."
sudo apt-get install -y unzip

# install at
echo "🔧 Installing at utility..."
sudo apt-get install -y at || true
sudo systemctl enable --now atd || true


# Install VS Code
echo "🧠 Installing Visual Studio Code..."
sudo wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  > /etc/apt/sources.list.d/vscode.list
sudo apt-get update -y
sudo apt-get install -y code

# install chromium browser
echo "🌐 Installing Chromium browser..."
sudo apt-get install -y chromium-browser || apt-get install -y chromium

# install docker
echo "🐳 Installing Docker..."
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# install wireshark
echo "📡 Installing Wireshark..."
# Pre-answer the permission prompt
echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
# Prevent interactive prompts
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wireshark
sudo usermod -aG wireshark "$USERNAME"
echo "Wireshark installed and user $USERNAME added to wireshark group."

# enable ufw
echo "🔒 Enabling UFW firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 3389/tcp
sudo ufw enable
echo "UFW firewall enabled and configured."


# auto shutdown in 15 mins
echo "🕒 Scheduling auto-shutdown in 15 minutes..."
echo "shutdown -h now" | at now + 15 minutes || echo "⚠️ Failed to schedule shutdown"


echo "✅ Installation complete for user: $USER"
EOF



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
useradd -m -s /bin/bash "$USERNAME"

# Set the user password non-interactively
echo "${USERNAME}:${PASSWORD}" | chpasswd

# Add to sudo group (optional)
usermod -aG sudo "$USERNAME"
echo "✅ User $USERNAME created and added to sudo group."

# Disable root SSH login
sed -i '/^#\?PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "✅ Disabled SSH login for root."

# Restart SSH service to apply root login change
systemctl restart sshd
echo "🔄 SSH service restarted to apply changes."

# Lock root account
passwd -l root
echo "✅ Root account locked from login."

# sudo commands will work without password prompts
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
chmod 0440 "/etc/sudoers.d/$USERNAME"

# ----------------------------
# 🔧 Run all installations as root
# ----------------------------

echo "🔄 Updating apt packages..."
apt-get update -y

echo "🖥️ Installing Xfce Desktop Environment and xrdp..."
apt-get install -y xfce4 xfce4-goodies xrdp
systemctl enable xrdp
adduser xrdp ssl-cert
systemctl restart xrdp

echo "🔧 Installing unzip utility..."
apt-get install -y unzip

echo "🔧 Installing at utility..."
apt-get install -y at || true
systemctl enable --now atd || true

echo "🧠 Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  > /etc/apt/sources.list.d/vscode.list
apt-get update -y
apt-get install -y code

echo "🌐 Installing Chromium browser..."
apt-get install -y chromium-browser || apt-get install -y chromium

echo "🐳 Installing Docker..."
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

echo "📡 Installing Wireshark..."
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get install -y wireshark
usermod -aG wireshark "$USERNAME"
echo "Wireshark installed and user $USERNAME added to wireshark group."

echo "🔒 Enabling UFW firewall..."
ufw allow OpenSSH
ufw allow 3389/tcp
ufw enable
echo "UFW firewall enabled and configured."

echo "🕒 Scheduling auto-shutdown in 15 minutes..."
echo "shutdown -h now" | at now + 15 minutes || echo "⚠️ Failed to schedule shutdown"

echo "✅ All installations and configurations completed successfully."
#  Run user-level config in heredoc

sudo -i -u "$USERNAME" bash <<'EOF'
echo "=== Running user-specific config as: $(whoami) ==="
echo "xfce4-session" > ~/.xsession
echo "✅ User-specific configuration complete for: $(whoami)"
EOF

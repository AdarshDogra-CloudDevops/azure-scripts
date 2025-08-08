#Ensure script runs as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You must run this script as Administrator!"
    exit 1
}   
Write-Host "=== Starting VM setup script ==="

#disable windows firewall
Write-Host "Disabling Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

#disable server manager pop up
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask 

Start-Sleep -Seconds 10  

#installing Chocolatey
Write-Host "Installing Chocolatey..."   
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Wait to ensure choco is in PATH
Start-Sleep -Seconds 5  

# Install required applications via Chocolatey  

#install google chrome
Write-Host "Installing Google Chrome..."    
choco install googlechrome -y --force

param (
    [string]$Username,
    [string]$Password
)


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

#install Azure storage explorer
Write-Host "Installing Azure Storage Explorer..."
choco install azurestorageexplorer -y --force  --ignore-checksums

# Path to Desktop
$desktop = [Environment]::GetFolderPath("Desktop")

# Fetching credentials
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)


# Save username & password to file (not recommended for production)
$vmDetailsFile = "$desktop\VMDetails.txt"
"Username: $($cred.UserName)" | Out-File -FilePath $vmDetailsFile -Encoding UTF8
"Password: $($cred.GetNetworkCredential().Password)" | Out-File -FilePath $vmDetailsFile -Append -Encoding UTF8

Write-Host "VMDetails.txt created on Desktop."

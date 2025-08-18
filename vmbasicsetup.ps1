# Transcript folder
$mainLogFolder = "C:\Users\Public\Downloads\Logs"
if (-not (Test-Path $mainLogFolder)) {
    New-Item -ItemType Directory -Path $mainLogFolder -Force | Out-Null
}

# Start transcript 
$mainLogFile = Join-Path $mainLogFolder ("MainScriptLog_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".txt")
Start-Transcript -Path $mainLogFile -Append

# Ensure script runs as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You must run this script as Administrator!"
    exit 1
}


Write-Host "=== Starting VM setup script ==="

# Disable Windows Firewall
Write-Host "Disabling Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

#disable server manager pop up
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask 

Start-Sleep -Seconds 10  

# Install Chocolatey
Write-Host "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Wait to ensure choco is in PATH
Start-Sleep -Seconds 5

# Install required applications via Chocolatey
Write-Host "Installing Google Chrome..."
choco install googlechrome -y --force  --ignore-checksums

Write-Host "Installing Visual Studio Code..."
choco install vscode -y --force

Write-Host "Installing Power BI Desktop..."
choco install powerbi -y --force  --ignore-checksums

# Stop transcript for the main script
Stop-Transcript
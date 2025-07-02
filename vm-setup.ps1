# Ensure script runs as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You must run this script as Administrator!"
    exit 1
}

Write-Host "=== Starting VM setup script ==="

# Disable Windows Firewall
Write-Host "Disabling Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Install Chocolatey
Write-Host "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Wait a bit to ensure choco is in PATH
Start-Sleep -Seconds 5

# Install required applications via Chocolatey
Write-Host "Installing Google Chrome..."
choco install googlechrome -y --force

Write-Host "Installing Visual Studio Code..."
choco install vscode -y --force

Write-Host "Installing Power BI Desktop..."
choco install powerbi -y --force

# Create a second script for shortcut & VMDetails creation
$secondaryScript = @'
$desktop = [Environment]::GetFolderPath("Desktop")
$WshShell = New-Object -ComObject WScript.Shell

# Azure Portal shortcut
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$azurePortalShortcut = "$desktop\Azure Portal.lnk"
if (Test-Path $chromePath) {
    $shortcut = $WshShell.CreateShortcut($azurePortalShortcut)
    $shortcut.TargetPath = $chromePath
    $shortcut.Arguments = "https://portal.azure.com"
    $shortcut.IconLocation = $chromePath
    $shortcut.Save()
    Write-Host "Azure Portal shortcut created successfully."
} else {
    Write-Warning "Chrome not found at $chromePath. Azure Portal shortcut not created."
}

# VMDetails.txt with hardcoded credentials
$vmDetailsFile = "$desktop\VMDetails.txt"
$hardcodedUsername = "azureadmin"
$hardcodedPassword = "P@ssword1234!"
"Username: $hardcodedUsername" | Out-File -FilePath $vmDetailsFile -Encoding UTF8
"Password: $hardcodedPassword" | Out-File -FilePath $vmDetailsFile -Append -Encoding UTF8
Write-Host "VMDetails.txt created successfully."
'@

$scriptPath = "C:\CreateShortcuts.ps1"
$secondaryScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "Secondary script created at $scriptPath"

# Schedule the secondary script to run at next logon for azureadmin
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "azureadmin"
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "CreateShortcutsAtLogon" -Description "Create Azure Portal shortcut and VMDetails.txt" -User "azureadmin" -RunLevel Highest -Force

Write-Host "Scheduled task 'CreateShortcutsAtLogon' created. It will run at next login of azureadmin."

Write-Host "✅ VM setup complete. Applications installed; shortcuts and VMDetails will be created at next login."

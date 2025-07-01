# Ensure script runs as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You must run this script as Administrator!"
    exit 1
}

Write-Host "=== Starting VM setup script ==="

# Disable Windows Defender Firewall on all profiles
Write-Host "Disabling Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Install Chocolatey
Write-Host "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Wait to ensure choco is available in PATH
Start-Sleep -Seconds 5

# Install required applications via Chocolatey
Write-Host "Installing Google Chrome..."
choco install googlechrome -y --force

Write-Host "Installing Visual Studio Code..."
choco install vscode -y --force

Write-Host "Installing Power BI Desktop..."
choco install powerbi -y --force

# Paths for desktop shortcuts
$desktop = [Environment]::GetFolderPath('Desktop')

# Create shortcuts for applications
Write-Host "Creating shortcuts on Desktop..."

# Shortcut for Google Chrome
$chromeShortcut = "$desktop\Google Chrome.lnk"
$chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromePath) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($chromeShortcut)
    $shortcut.TargetPath = $chromePath
    $shortcut.Save()
}

# Shortcut for Visual Studio Code
$vscodeShortcut = "$desktop\Visual Studio Code.lnk"
$vscodePath = "${env:ProgramFiles}\Microsoft VS Code\Code.exe"
if (Test-Path $vscodePath) {
    $shortcut = $WshShell.CreateShortcut($vscodeShortcut)
    $shortcut.TargetPath = $vscodePath
    $shortcut.Save()
}

# Shortcut for Power BI Desktop
$powerBIShortcut = "$desktop\Power BI Desktop.lnk"
$powerBIPath = "${env:ProgramFiles}\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
if (Test-Path $powerBIPath) {
    $shortcut = $WshShell.CreateShortcut($powerBIShortcut)
    $shortcut.TargetPath = $powerBIPath
    $shortcut.Save()
}

# Create browser shortcut to Azure Portal (opens Chrome directly to the portal URL)
Write-Host "Creating Azure Portal shortcut on Desktop..."
$azurePortalShortcut = "$desktop\Azure Portal.lnk"
if (Test-Path $chromePath) {
    $shortcut = $WshShell.CreateShortcut($azurePortalShortcut)
    $shortcut.TargetPath = $chromePath
    $shortcut.Arguments = "https://portal.azure.com"
    $shortcut.IconLocation = $chromePath
    $shortcut.Save()
}


# Create VMDetails.txt with username & password
$vmDetailsFile = "$desktop\VMDetails.txt"
"Username: $($args[0])" | Out-File -FilePath $vmDetailsFile -Encoding UTF8
"Password: $($args[1])" | Out-File -FilePath $vmDetailsFile -Append -Encoding UTF8

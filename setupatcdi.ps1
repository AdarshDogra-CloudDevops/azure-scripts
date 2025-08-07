#Ensure script runs as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You must run this script as Administrator!"
    exit 1
}   
Write-Host "=== Starting VM setup script ==="

#installing Chocolatey
Write-Host "Installing Chocolatey..."   
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Wait to ensure choco is in PATH
Start-Sleep -Seconds 5  

# Install required applications via Chocolatey  

#install vs code
Write-Host "Installing Visual Studio Code..."
choco install vscode -y --force

#install google chrome
Write-Host "Installing Google Chrome..."    
choco install googlechrome -y --force


#vs code shortcut
$vsCodePath = "C:\Program Files\Microsoft VS Code\Code.exe"
$vsCodeShortcut = "$desktop\Visual Studio Code.lnk"
if (Test-Path $vsCodePath) {
    $shortcut = $WshShell.CreateShortcut($vsCodeShortcut)
    $shortcut.TargetPath = $vsCodePath
    $shortcut.IconLocation = $vsCodePath
    $shortcut.Save()
    Write-Host "Visual Studio Code shortcut created successfully."
} else {
    Write-Warning "VS Code not found at $vsCodePath. Shortcut not created."
}

#azure portal shortcut
$desktop = [Environment]::GetFolderPath("Desktop")
$WshShell = New-Object -ComObject WScript.Shell
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




# Get arguments passed from ARM template
param (
    [string]$AdminUsername,
    [string]$AdminPassword
)

# Disable Windows Defender Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Set Desktop path for the admin user
$desktopPath = "C:\Users\$AdminUsername\Desktop"

# Helper function to install apps
function Install-App {
    param (
        [string]$url,
        [string]$installerName,
        [string]$arguments = ""
    )
    $output = "$env:TEMP\$installerName"
    Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
    Start-Process -FilePath $output -ArgumentList $arguments -Wait
}

# Install Google Chrome
Install-App -url "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -installerName "chrome_installer.exe" -arguments "/silent /install"

# Install VS Code
Install-App -url "https://update.code.visualstudio.com/latest/win32-x64-user/stable" -installerName "vscode_installer.exe" -arguments "/silent"

# Install Power BI Desktop
Install-App -url "https://download.microsoft.com/download/6/3/2/632DC9EC-4F49-4D34-A2D6-9F8CD64F8A7C/PBIDesktopSetup_x64.exe" -installerName "PBIDesktopSetup_x64.exe" -arguments "/quiet"

# Create desktop shortcuts
$WScriptShell = New-Object -ComObject WScript.Shell

# Chrome shortcut
$chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromePath) {
    $chromeShortcut = "$desktopPath\Google Chrome.lnk"
    $chromeLink = $WScriptShell.CreateShortcut($chromeShortcut)
    $chromeLink.TargetPath = $chromePath
    $chromeLink.Save()
}

# VS Code shortcut
$vsCodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
if (Test-Path $vsCodePath) {
    $vsCodeShortcut = "$desktopPath\Visual Studio Code.lnk"
    $vsCodeLink = $WScriptShell.CreateShortcut($vsCodeShortcut)
    $vsCodeLink.TargetPath = $vsCodePath
    $vsCodeLink.Save()
}

# Power BI shortcut
$powerBIPath = "${env:ProgramFiles}\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
if (Test-Path $powerBIPath) {
    $powerBILink = $WScriptShell.CreateShortcut("$desktopPath\Power BI Desktop.lnk")
    $powerBILink.TargetPath = $powerBIPath
    $powerBILink.Save()
}

# Azure Portal browser shortcut (.url file instead of .lnk)
$azurePortalShortcut = "$desktopPath\Azure Portal.url"
Set-Content -Path $azurePortalShortcut -Value "[InternetShortcut]`nURL=https://portal.azure.com"

# Create VMDetails.txt with actual provided username and password
$vmDetails = "Username: $AdminUsername`nPassword: $AdminPassword"
Set-Content -Path "$desktopPath\VMDetails.txt" -Value $vmDetails

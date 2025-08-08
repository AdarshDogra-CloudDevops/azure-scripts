#Ensure script runs as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You must run this script as Administrator!"
    exit 1
}   
Write-Host "=== Starting VM setup script ==="

#server manager pop up
Write-Host "Disabling Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False


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

#install vs code
Write-Host "Installing Visual Studio Code..."
choco install vscode -y --force

# Wait to ensure vs intsallaion is complete
Start-Sleep -Seconds 15  

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

# Create secondary PowerShell script
$secondaryScript = @'
$desktop = [Environment]::GetFolderPath("Desktop")
$WshShell = New-Object -ComObject WScript.Shell

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
'@

$scriptPath = "C:\CreateShortcuts.ps1"
$secondaryScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "Secondary script created at $scriptPath"

# Create VBScript launcher
$escapedScriptPath = $scriptPath -replace '\\', '\\\\'  # escape backslashes for safety
$vbscript = @"
Set objShell = CreateObject("Wscript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -File ""$escapedScriptPath""", 0, False
"@
$vbscriptPath = "C:\launch-hidden.vbs"
$vbscript | Out-File -FilePath $vbscriptPath -Encoding ASCII
Write-Host "VBScript launcher created at $vbscriptPath"


# Schedule the VBScript launcher to run completely hidden at next login
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$vbscriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "azureadmin"
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "CreateShortcutsAtLogon" -Description "Create Azure Portal shortcut and VMDetails.txt silently using VBScript" -User "azureadmin" -RunLevel Highest -Force

Write-Host "Scheduled task 'CreateShortcutsAtLogon' created. It will run completely silently at next login of azureadmin."

Write-Host "✅ VM setup complete. Applications installed; shortcut will be created silently at next login."



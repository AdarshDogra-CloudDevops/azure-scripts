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

# Create secondary PowerShell script
$secondaryScript = @"
`$Username = "$Username"
`$Password = "$Password"
`$desktop = [Environment]::GetFolderPath("Desktop")
`$WshShell = New-Object -ComObject WScript.Shell

# Fetching credentials
`$securePassword = ConvertTo-SecureString `$Password -AsPlainText -Force
`$cred = New-Object System.Management.Automation.PSCredential (`$Username, `$securePassword)

# Save username & password to file
`$vmDetailsFile = "`$desktop\VMDetails.txt"
"Username: $Username" | Out-File -FilePath `$vmDetailsFile -Encoding UTF8
"Password: $Password" | Out-File -FilePath `$vmDetailsFile -Append -Encoding UTF8
"@

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

Write-Host "✅ VM setup complete. Applications installed; shortcuts and VMDetails will be created silently at next login."


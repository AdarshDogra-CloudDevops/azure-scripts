param (
    [string]$adminUsername,
    [string]$adminPassword,
    [string]$storageAccountName,
    [string]$containerName
)

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

# Disable Server Manager pop-up if exists
if (Get-ScheduledTask -TaskName ServerManager -ErrorAction SilentlyContinue) {
    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask
}

Start-Sleep -Seconds 10  

# Create the PowerShell script that downloads once
$secondaryScript = @"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
`$storageAccountName = "$storageAccountName"
`$containerName = "$containerName"
`$fileUrl = "https://\$storageAccountName.blob.core.windows.net/\$containerName/StrapiEcsReport.pdf"

`$saveFolder = Join-Path \$HOME "Downloads"
if (-not (Test-Path \$saveFolder)) { New-Item -ItemType Directory -Path \$saveFolder | Out-Null }

try {
    `$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    `$fileName = "StrapiEcsReport_\$timestamp.pdf"
    `$destinationPath = Join-Path \$saveFolder \$fileName

    Invoke-WebRequest -Uri \$fileUrl -OutFile \$destinationPath -ErrorAction Stop
} catch {
    # Optional: log errors
}
"@

$scriptPath = "C:\ContinuousDownload.ps1"
$secondaryScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "Secondary script created at $scriptPath"

# Create a scheduled task to run this script every minute silently
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
$trigger.Repetition.Interval = (New-TimeSpan -Minutes 1)

Register-ScheduledTask -Action $action -Trigger $trigger `
    -TaskName "DownloadEveryMinute" `
    -Description "Download StrapiEcsReport.pdf silently every minute" `
    -User $adminUsername `
    -Password $adminPassword `
    -RunLevel Highest -Force

Write-Host "✅ Scheduled task 'DownloadEveryMinute' created. Will run silently every minute."

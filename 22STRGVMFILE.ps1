param (
    [string]$adminUsername,
    [string]$adminPassword,
    [string]$storageAccountName,
    [string]$containerName
)

# Ensure script runs as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You must run this script as Administrator!"
    exit 1
}

Write-Host "=== Starting VM setup script ==="

# Disable Windows Firewall
Write-Host "Disabling Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Disable Server Manager popup if exists
if (Get-ScheduledTask -TaskName ServerManager -ErrorAction SilentlyContinue) {
    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask
}

Start-Sleep -Seconds 10

# Create folder for downloads
$downloadFolder = "C:\Downloads"
if (-not (Test-Path $downloadFolder)) { New-Item -ItemType Directory -Path $downloadFolder | Out-Null }

# Create the script to download the file
$secondaryScript = @"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

\$storageAccountName = "$storageAccountName"
\$containerName = "$containerName"
\$fileUrl = "https://$storageAccountName.blob.core.windows.net/$containerName/StrapiEcsReport.pdf"

\$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
\$fileName = "StrapiEcsReport_\$timestamp.pdf"
\$destinationPath = Join-Path "C:\Downloads" \$fileName

try {
    Invoke-WebRequest -Uri \$fileUrl -OutFile \$destinationPath -ErrorAction Stop
} catch {
    Add-Content -Path "C:\Downloads\DownloadError.log" -Value ("[{0}] Error: {1}" -f (Get-Date), \$_)
}
"@

$scriptPath = "C:\ContinuousDownload.ps1"
$secondaryScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "Secondary script created at $scriptPath"

# Create scheduled task
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

Write-Host "✅ Scheduled task 'DownloadEveryMinute' created."
Write-Host "Files will appear in C:\Downloads"

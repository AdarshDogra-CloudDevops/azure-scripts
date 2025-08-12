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

# Create the secondary download script
$secondaryScript = @"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
\$uri = "https://$storageAccountName.blob.core.windows.net/$containerName/StrapiEcsReport.pdf"

# Create timestamped filename
\$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
\$output = "C:\Downloads\StrapiEcsReport_\$timestamp.pdf"

try {
    Invoke-WebRequest -Uri \$uri -OutFile \$output -ErrorAction Stop
} catch {
    Add-Content -Path "C:\Downloads\DownloadError.log" -Value ("[{0}] Error: {1}" -f (Get-Date), \$_)
}
"@

$scriptPath = "C:\Downloads\download_script.ps1"
$secondaryScript | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "Secondary script created at $scriptPath"

# Create scheduled task
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
$trigger.Repetition.Interval = (New-TimeSpan -Minutes 1)
$trigger.RepetitionDuration = (New-TimeSpan -Days 365)   # 1 year

Register-ScheduledTask -Action $action -Trigger $trigger `
    -TaskName "DownloadEveryMinute" `
    -Description "Download StrapiEcsReport.pdf silently every minute" `
    -User $adminUsername `
    -Password $adminPassword `
    -RunLevel Highest -Force

Write-Host "✅ Scheduled task 'DownloadEveryMinute' created."
Write-Host "Files will appear in C:\Downloads"

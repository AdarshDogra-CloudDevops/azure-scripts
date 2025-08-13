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

# Disable Server Manager popup
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask 

Start-Sleep -Seconds 10  

# Path to secondary script
$secondaryScriptPath = "C:\SecondaryScript.ps1"

# Create secondary PowerShell script
$secondaryScript = @"
# Wait 3 minutes before starting work
Start-Sleep -Seconds 120

`$storageAccountName="$storageAccountName"
`$containerName="$containerName"
`$adminUsername="$adminUsername"
`$adminPassword="$adminPassword"
`$fileUrl = "https://$storageAccountName.blob.core.windows.net/$containerName/StrapiEcsReport.pdf"

# Always save to the admin user's Downloads folder
`$saveFolder = "C:\Users\azureadmin\Downloads"
if (-not (Test-Path `$saveFolder)) { 
    New-Item -ItemType Directory -Path `$saveFolder -Force | Out-Null 
}

Write-Host "Starting continuous download every 30 seconds..."

while (`$true) {
    try {
        # Create a unique filename with timestamp
        `$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        `$fileName = "StrapiEcsReport_`$timestamp.pdf"
        `$destinationPath = Join-Path `$saveFolder `$fileName

        Invoke-WebRequest -Uri `$fileUrl -OutFile `$destinationPath -ErrorAction Stop
        Write-Host "✅ File downloaded successfully at $(Get-Date) -> `$destinationPath"
    }
    catch {
        Write-Host "❌ Download failed at $(Get-Date)"
    }

    Start-Sleep -Seconds 30
}
"@

# Save secondary script to disk
Set-Content -Path $secondaryScriptPath -Value $secondaryScript -Encoding UTF8

# Register Task Scheduler job to run secondary script after startup
Write-Host "Registering Task Scheduler task..."

$taskName = "RunSecondaryScriptAfterDelay"

# Startup trigger (no delay param — delay handled inside script)
$triggerStartup = New-ScheduledTaskTrigger -AtStartup

# Action: run PowerShell to execute secondary script
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$secondaryScriptPath`""

# Run as SYSTEM so it works without password prompts
Register-ScheduledTask -TaskName $taskName -Trigger $triggerStartup -Action $action -RunLevel Highest -User "SYSTEM" -Force

Write-Host "✅ Task Scheduler job created. Secondary script will run after 3 minutes and save files in C:\Users\$adminUsername\Downloads"

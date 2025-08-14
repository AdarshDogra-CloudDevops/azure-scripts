param (
    [string]$adminUsername,
    [securestring]$adminPassword,
    [string]$storageAccountName,
    [string]$containerName
)

# Transcript folder
$mainLogFolder = "C:\Users\Public\Downloads\Logs"
if (-not (Test-Path $mainLogFolder)) {
    New-Item -ItemType Directory -Path $mainLogFolder -Force | Out-Null
}

# Start transcript for the main script
$mainLogFile = Join-Path $mainLogFolder ("MainScriptLog_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".txt")
Start-Transcript -Path $mainLogFile -Append

# Ensure script runs as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You must run this script as Administrator!"
    Stop-Transcript
    exit 1
}   
Write-Host "=== Starting VM setup script ==="

# Disable Windows Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
write-host "Disabled Windows Firewall..."

# Disable Server Manager popup
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask 
Start-Sleep -Seconds 10  
write-host "Disabled Server Manager popup..."

# Path to secondary script
$secondaryScriptPath = "C:\SecondaryScript.ps1"
write-host "Created secondary script at $secondaryScriptPath"

# Create secondary PowerShell script
$secondaryScript = @"
# Wait 3 minutes before starting work
Start-Sleep -Seconds 60

# Start transcript for logging
`$logFolder = "C:\Users\Public\Downloads\Logs"
if (-not (Test-Path `$logFolder)) { 
    New-Item -ItemType Directory -Path `$logFolder -Force | Out-Null 
}
`$logFile = Join-Path `$logFolder ("DownloadLog_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".txt")
Start-Transcript -Path `$logFile -Append

`$storageAccountName="$storageAccountName"
`$containerName="$containerName"
`$adminUsername="$adminUsername"
`$adminPassword="$adminPassword"
`$fileUrl = "https://$storageAccountName.blob.core.windows.net/$containerName/StrapiEcsReport.pdf"

# Always save to the admin user's Downloads folder
`$saveFolder = "C:\Users\Public\Downloads"
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

# End transcript when script stops
Stop-Transcript
"@

# Save secondary script to disk
Set-Content -Path $secondaryScriptPath -Value $secondaryScript -Encoding UTF8
write-host "Secondary script created at $secondaryScriptPath"

# Register Task Scheduler job to run secondary script after logon
Write-Host "Registering Task Scheduler task..."
$taskName = "RunSecondaryScriptAfterDelay"

# Trigger at startup (or logon if you want)
$triggerStartup = New-ScheduledTaskTrigger -AtLogOn -User $adminUsername
write-host "Trigger set to run at logon for user: $adminUsername"

# Action: run PowerShell to execute secondary script
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$secondaryScriptPath`""
write-host "Action set to run PowerShell script: $secondaryScriptPath"

# Register as User account
# Convert SecureString password to plain text
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))
write-host "password converted to plain text for task registration"

Register-ScheduledTask -TaskName $taskName -Trigger $triggerStartup -Action $action -RunLevel Highest -User $adminUsername -Password $plainPassword -Force
Write-Host "✅ Task Scheduler job created. Secondary script will run after 2 minutes and save files in C:\Users\Public\Downloads"

# Stop transcript for the main script
Stop-Transcript

param (
    [string]$adminUsername,
    [string]$adminPassword
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

# Create secondary PowerShell script
$secondaryScript = @"
$fileUrl = "https://teststrg4321.blob.core.windows.net/test-conatiner/Strapi%20Ecs%20Report.pdf"
$saveFolder = "C:\Users\azureadmin\Downloads"

Write-Host "Starting continuous download every 30 seconds..."

while ($true) {
    try {
        # Create a unique filename with timestamp
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = "Strapi_Ecs_Report_$timestamp.pdf"
        $destinationPath = Join-Path $saveFolder $fileName

        Invoke-WebRequest -Uri $fileUrl -OutFile $destinationPath -ErrorAction Stop
        Write-Host "✅ File downloaded successfully at $(Get-Date) -> $destinationPath"
    }
    catch {
        Write-Host "❌ Download failed at $(Get-Date)"
    }

    Start-Sleep -Seconds 30
}
"@
$scriptPath = "C:\ContinuousDownload.ps1"
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
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $adminUsername

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "DownloadAtLogon" 
-Description "download file silently using VBScript" -User $adminUsername
 -RunLevel Highest -Force

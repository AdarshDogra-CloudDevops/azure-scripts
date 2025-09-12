# Ensure script runs as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "You must run this script as Administrator!"
    Stop-Transcript
    exit 1
}   
Write-Host "=== Starting VM setup script ==="


# Disable Server Manager popup
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask 
Start-Sleep -Seconds 10  
write-host "Disabled Server Manager popup..."

#ensure edge is installed
$edge = Get-Command "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ErrorAction SilentlyContinue
if ($edge -eq $null) {
    Write-Host "Edge not found. Installing Edge..."
    Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2135547" -OutFile "$env:TEMP\MicrosoftEdgeSetup.exe"
    Start-Process -FilePath "$env:TEMP\MicrosoftEdgeSetup.exe" -ArgumentList "/silent /install" -Wait
    Remove-Item "$env:TEMP\MicrosoftEdgeSetup.exe"
    Write-Host "Edge installed."
} else {
    Write-Host "Edge is already installed."
}
#create desktop shorcut for azure portal
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:Public\Desktop\Azure Portal.lnk")    
$Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$Shortcut.Arguments = "https://portal.azure.com"
$Shortcut.IconLocation = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe, 0"
$Shortcut.Save()
Write-Host "Created Azure Portal shortcut on desktop."

# Install Azure CLI
$az = Get-Command "az" -ErrorAction SilentlyContinue
if ($az -eq $null) {
    Write-Host "Azure CLI not found. Installing Azure CLI..."
    Invoke-WebRequest -Uri "https://aka.ms/installazurecliwindows" -OutFile "$env:TEMP\AzureCLI.msi"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $env:TEMP\AzureCLI.msi /quiet" -Wait
    Remove-Item "$env:TEMP\AzureCLI.msi"
    Write-Host "Azure CLI installed."
} else {
    Write-Host "Azure CLI is already installed."
}

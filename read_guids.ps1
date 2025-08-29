# read_guids.ps1
$guidFile = "C:\VM_GUIDs.txt"
$outFile  = "C:\Packages\Outputs\guids.json"

if (Test-Path $guidFile) {
    $guids = Get-Content $guidFile
    $json  = @{ VM_GUIDs = $guids } | ConvertTo-Json -Depth 2
    # Ensure output directory exists
    $outDir = Split-Path $outFile
    if (!(Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }
    $json | Out-File -FilePath $outFile -Encoding utf8
}
else {
    Write-Output "File $guidFile not found."
}

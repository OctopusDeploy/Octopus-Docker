param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

TeamCity-Block("Setting metadata version to current") {
    $filePath = './Testing/Import/metadata.json'

    ((Get-Content -path $filePath -Raw) -replace '"DatabaseVersion": "0.0.0"', ('"DatabaseVersion": "'+$OctopusVersion+'"')) | Set-Content -Path $filePath   
}
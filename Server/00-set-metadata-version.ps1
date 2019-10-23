param (
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

$delimiters = '-', '+'
$currentVersion = $OctopusVersion.Split($delimiters)[0]

TeamCity-Block("Setting metadata version to " + $currentVersion) {
    $filePath = './Testing/Import/metadata.json'    
    
    ((Get-Content -path $filePath -Raw) -replace '"DatabaseVersion": "0.0.0"', ('"DatabaseVersion": "'+$currentVersion+'"')) | Set-Content -Path $filePath   
}

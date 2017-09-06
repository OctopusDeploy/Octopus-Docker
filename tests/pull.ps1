param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$TentacleVersion
)

$env:OCTOPUS_VERSION=$OctopusVersion

$IncludeTentacle = (($TentacleVersion -ne $null) -and ($TentacleVersion -ne ""))

if ($IncludeTentacle) {
  $env:OCTOPUS_IMAGE_SUFFIX = "preview"
} else {
  $env:OCTOPUS_IMAGE_SUFFIX = "prerelease"
}

Write-Host "docker login -u=`"$UserName`" -p=`"#########`""
& docker login -u="$UserName" -p="$Password"
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "docker-compose --file .\docker-compose.yml pull"
& docker-compose --file .\docker-compose.yml pull
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

if ($IncludeTentacle) {
  $env:TENTACLE_VERSION=$TentacleVersion;
  Write-Host "docker-compose --file .\tests\docker-compose.yml --file .\docker-compose.yml pull"
  & docker-compose --file .\tests\docker-compose.yml pull --file .\docker-compose.yml
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

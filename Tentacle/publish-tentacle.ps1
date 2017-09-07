param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$TentacleVersion,
  [switch]$Release
)

function Docker-Login() {
  write-host "docker login -u=`"$UserName`" -p=`"#########`""
  & docker login -u="$UserName" -p="$Password"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

function Push-Image() {
  param (
    [Parameter(Mandatory=$true)]
    [string] $ImageName
  )

  write-host "docker push $ImageName"
  & docker push $ImageName
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

function Set-Tag($tag) {
  Write-Host "docker tag 'octopusdeploy/octopusdeploy-tentacle-prerelease:$TentacleVersion' '$tag'"
  & docker tag "octopusdeploy/octopusdeploy-tentacle-prerelease:$TentacleVersion" "$tag"
}

Docker-Login

if ($Release) {
  Set-Tag "octopusdeploy/octopusdeploy-tentacle-preview:$TentacleVersion"
  Push-Image "octopusdeploy/octopusdeploy-tentacle-preview:$TentacleVersion"

  $latestVersion = (Invoke-RestMethod "https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle/version")
  if ($latestVersion -eq $TentacleVersion) {
    Set-Tag "octopusdeploy/octopusdeploy-tentacle-preview:latest"
    Push-Image "octopusdeploy/octopusdeploy-tentacle-preview:latest"
  }
} else {
  Push-Image "octopusdeploy/octopusdeploy-tentacle-prerelease:$TentacleVersion"
}


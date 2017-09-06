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
  Write-Host "docker tag 'octopusdeploy/octopusdeploy-tentacle-prerelease:$Version' '$tag'"
  & docker tag "octopusdeploy/octopusdeploy-tentacle-prerelease:$Version" "$tag"
}

Docker-Login

if ($Release) {
  Set-Tag "octopusdeploy/octopusdeploy-tentacle-preview:$Version"
  Push-Image "octopusdeploy/octopusdeploy-tentacle-preview:$Version"

  $latestVersion = (Invoke-RestMethod "https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle/version")
  if ($latestVersion -eq $version) {
    Set-Tag "octopusdeploy/octopusdeploy-tentacle-preview:latest"
    Push-Image "octopusdeploy/octopusdeploy-tentacle-preview:latest"
  }
} else {
  Push-Image "octopusdeploy/octopusdeploy-tentacle-prerelease:$Version"
}


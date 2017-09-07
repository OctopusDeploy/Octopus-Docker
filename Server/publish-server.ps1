param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
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
  Write-Host "docker tag 'octopusdeploy/octopusdeploy-prerelease:$OctopusVersion' '$tag'"
  & docker tag "octopusdeploy/octopusdeploy-prerelease:$OctopusVersion" "$tag"
}

Docker-Login

if ($Release) {
  Set-Tag "octopusdeploy/octopusdeploy-preview:$OctopusVersion"
  Push-Image "octopusdeploy/octopusdeploy-preview:$OctopusVersion"

  $latestVersion = (Invoke-RestMethod "https://octopus.com/downloads/latest/WindowsX64/OctopusServer/version")
  if ($latestVersion -eq $OctopusVersion) {
    Set-Tag "octopusdeploy/octopusdeploy-preview:latest"
    Push-Image "octopusdeploy/octopusdeploy-preview:latest"
  }
} else {
  Push-Image "octopusdeploy/octopusdeploy-prerelease:$OctopusVersion"
}

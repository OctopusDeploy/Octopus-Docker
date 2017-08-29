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

function Get-ImageName() {
  param (
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [bool]$IsRelease=$False
  )

  $image = "octopusdeploy/octopusdeploy-tentacle"

  if ($IsRelease) {
   $image += "-preview"
  } else {
   $image += "-prerelease"
  }

  return $image + ":$Version"
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

function TagRelease() {
  write-host "docker tag $(Get-ImageName $TentacleVersion $False) $(Get-ImageName $TentacleVersion $True)"
  & docker tag $(Get-ImageName $TentacleVersion $False) $(Get-ImageName $TentacleVersion $True)
}

function Publish() {
  param(
    [Parameter(Mandatory=$true)]
    [bool]$IsRelease = $False
  )
  Push-Image $(Get-ImageName $TentacleVersion $IsRelease)
}

Docker-Login

if ($Release) {
  TagRelease
  Publish -IsRelease $True
} else {
  Publish -IsRelease $False
}

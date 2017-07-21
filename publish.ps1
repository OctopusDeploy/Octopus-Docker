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

function Get-ImageName() {
param (
  [Parameter(Mandatory=$true)]
  [ValidateSet("server","tentacle")]
  [string]$AppType,
  [Parameter(Mandatory=$true)]
  [string]$Version,
  [bool]$IsRelease=$False
  )

  $image = "octopusdeploy/octopusdeploy"

  if($AppType -eq "tentacle"){
    $image += "-tentacle";
  }

  if($IsRelease) {
   $image += "-preview"
  } else {
   $image += "-prerelease"
  }

  return $image + ":$Version"
}

function Push-Image(){
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
  Write-Host "docker tag $(Get-ImageName 'server' $OctopusVersion $False) $(Get-ImageName 'server' $OctopusVersion $True)"
  & docker tag $(Get-ImageName 'server' $OctopusVersion $False) $(Get-ImageName 'server' $OctopusVersion $True)

  write-host "docker tag $(Get-ImageName 'tentacle' $OctopusVersion $False) $(Get-ImageName 'tentacle' $OctopusVersion $True)"
  & docker tag $(Get-ImageName 'tentacle' $OctopusVersion $False) $(Get-ImageName 'tentacle' $OctopusVersion $True)
}

function Publish(){
param(
  [Parameter(Mandatory=$true)]
  [bool]$IsRelease = $False
  )
  Push-Image $(Get-ImageName "server" $OctopusVersion $IsRelease)
  Push-Image $(Get-ImageName "tentacle" $OctopusVersion $IsRelease)
}

Docker-Login
if($Release) {
  TagRelease
  Publish -IsRelease $True
} else {
  Publish -IsRelease $False
}

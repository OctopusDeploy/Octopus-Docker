param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password,
  [Parameter(Mandatory=$true)]		
  [string]$OctopusVersion
)

write-host "docker login -u=`"$UserName`" -p=`"#########`""
& docker login -u="$UserName" -p="$Password"
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

write-host "docker push octopusdeploy/octopusdeploy-prerelease:$OctopusVersion"
& docker push octopusdeploy/octopusdeploy-prerelease:$OctopusVersion
exit $LASTEXITCODE
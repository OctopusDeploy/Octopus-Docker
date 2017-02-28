param (
  [Parameter(Mandatory=$true)]
  [PSCredential][System.Management.Automation.Credential()]$Credential,

  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion
)

write-host "docker login -u=`"$($Credential.UserName)`" -p=`"#########`""
docker login -u="$($Credential.UserName)" -p="$($Credential.GetNetworkCredential().Password)"
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

write-host "docker push octopusdeploy/octopusdeploy:$OctopusVersion"
docker push octopusdeploy/octopusdeploy:$OctopusVersion
exit $LASTEXITCODE

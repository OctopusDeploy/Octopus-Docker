param (
  [Parameter(Mandatory=$false)]
  [string]$OctopusVersion="latest"
)

. ./Scripts/build-common.ps1

function Get-OctopusServerVersion($version){
  $dockerImage = "octopusdeploy/octopusdeploy:$version"

  if ("latest" -eq $version){
    & docker pull $dockerImage | out-null
    $json = (& docker image inspect octopusdeploy/octopusdeploy:$version | convertfrom-json)
    return $json[0].ContainerConfig.Labels.'org.label-schema.version'
  } else {
    return $version;
  }
}

TeamCity-Block("Setting metadata version") {
  $actualVersion = Get-OctopusServerVersion($OctopusVersion)

  if ($null -eq $actualVersion){
    throw "Could not determine the actual version of Octopus Server."
  } else {
    write-host "Determined version of Octopus Server to be: $actualVersion"

    $filePath = './Testing/Import/metadata.json'
    ((Get-Content -path $filePath -Raw) -replace '"DatabaseVersion": "0.0.0"', ('"DatabaseVersion": "'+$actualVersion+'"')) | Set-Content -Path $filePath   
  }
}

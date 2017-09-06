param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker",
  [Parameter(Mandatory=$true)]
  [string]$OctopusVersion,
  [Parameter(Mandatory=$false)]
  [string]$TentacleVersion
)

$IncludeTentacle = (($TentacleVersion -ne $null) -and ($TentacleVersion -ne ""))

if ($IncludeTentacle) {
  $env:OCTOPUS_IMAGE_SUFFIX = "preview"
} else {
  $env:OCTOPUS_IMAGE_SUFFIX = "prerelease"
}

write-host "Stopping '$ProjectName' compose project"
& "C:\Program Files\Docker Toolbox\docker-compose" --project-name $ProjectName stop

write-host "Removing '$ProjectName' compose project"
& "C:\Program Files\Docker Toolbox\docker-compose" --project-name $ProjectName down

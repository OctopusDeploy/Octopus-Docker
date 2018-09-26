# param (
#   [Parameter(Mandatory=$true)]
#   [string]$UserName,
#   [Parameter(Mandatory=$true)]
#   [string]$Password,
#   [Parameter(Mandatory=$true)]
#   [string]$OctopusVersion
# )

# . ./Scripts/build-common.ps1

# Confirm-RunningFromRootDirectory

# TeamCity-Block("Pull from private repo") {

# $imageVersion = Get-ImageVersion $TentacleVersion

# $env:OCTOPUS_VERSION=$imageVersion

# Docker-Login

# docker pull "octopusdeploy/octopusdeploy-prerelease:$imageVersion"

#   if ($LASTEXITCODE -ne 0) {
#     exit $LASTEXITCODE
#   }
# }
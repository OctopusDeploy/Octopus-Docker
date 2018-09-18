param (
  [Parameter()]
  [string]$TentacleVersion="3.22.0"
)
$VerbosePreference = "continue"

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

TeamCity-Block("Build") {
	$imageVersion = Get-ImageVersion $TentacleVersion
	docker build --pull --tag octopusdeploy/tentacle-prerelease:$imageVersion --build-arg TentacleVersion=$TentacleVersion --file Tentacle\Dockerfile .
	Write-Host "Created image with tag 'octopusdeploy/tentacle-prerelease:$imageVersion'"
}

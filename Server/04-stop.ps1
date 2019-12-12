param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

. ./Scripts/build-common.ps1
Confirm-RunningFromRootDirectory

TeamCity-Block("Stop and remove compose project") {
  Stop-DockerCompose $ProjectName .\Server\docker-compose.yml
}
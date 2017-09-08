param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

$OctopusServerContainer=$ProjectName+"_octopus_1";
$OctopusDBContainer=$ProjectName+"_db_1";

Wait-ForServiceToPassHealthCheck $OctopusDBContainer
Wait-ForServiceToPassHealthCheck $OctopusServerContainer

Check-IPAddress

Write-DebugInfo @($OctopusDBContainer, $OctopusServerContainer)

Copy-FilesToDockerContainer "$PSScriptRoot/../tests/scripts/" $OctopusServerContainer

write-host "-----------------------------------"
write-host "docker exec $OctopusServerContainer powershell -file /run-tests.ps1 -testfile octopus-server_spec.rb"
if (Test-Path ENV:TEAMCITY_PROJECT_NAME) {
  & docker exec --env tc_project_name=$ENV:TEAMCITY_PROJECT_NAME $OctopusServerContainer powershell -file c:\run-tests.ps1 -testfile octopus-server_spec.rb
} else {
  & docker exec $OctopusServerContainer powershell -file c:\run-tests.ps1 -testfile octopus-server_spec.rb
}
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
write-host "-----------------------------------"

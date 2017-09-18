param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

Start-TeamCityBlock "Run tests"

$OctopusServerContainer=$ProjectName+"_octopus_1";
$OctopusTentacleContainer=$ProjectName+"_tentacle_1";
$OctopusDBContainer=$ProjectName+"_db_1";

Wait-ForServiceToPassHealthCheck $OctopusDBContainer
Wait-ForServiceToPassHealthCheck $OctopusServerContainer
Wait-ForServiceToPassHealthCheck $OctopusTentacleContainer

Check-IPAddress

Write-DebugInfo @($OctopusDBContainer, $OctopusServerContainer, $OctopusTentacleContainer)

Copy-FilesToDockerContainer "$PSScriptRoot/../tests/scripts/" $OctopusServerContainer
Copy-FilesToDockerContainer "$PSScriptRoot/../tests/scripts/" $OctopusTentacleContainer

Start-TeamCityBlock "docker exec run-tests.ps1"
write-host "docker exec $OctopusServerContainer powershell -file /run-tests.ps1 -testfile tentacle_spec.rb"
if (Test-Path ENV:TEAMCITY_PROJECT_NAME) {
  & docker exec --env tc_project_name=$ENV:TEAMCITY_PROJECT_NAME $OctopusServerContainer powershell -file c:\run-tests.ps1 -testfile octopus-server_spec.rb
  & docker exec --env tc_project_name=$ENV:TEAMCITY_PROJECT_NAME $OctopusTentacleContainer powershell -file c:\run-tests.ps1 -testfile tentacle_spec.rb
} else {
  & docker exec $OctopusServerContainer powershell -file c:\run-tests.ps1 -testfile octopus-server_spec.rb
  & docker exec $OctopusTentacleContainer powershell -file c:\run-tests.ps1 -testfile tentacle_spec.rb
}
Stop-TeamCityBlock "docker exec run-tests.ps1"

Stop-TeamCityBlock "Run tests"
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

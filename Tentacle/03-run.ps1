param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

. ./Scripts/build-common.ps1

Confirm-RunningFromRootDirectory

Start-TeamCityBlock "Run tests"

$OctopusServerContainer=$ProjectName+"_octopus_1";
$OctopusListeningTentacleContainer=$ProjectName+"_listeningtentacle_1";
$OctopusPollingTentacleContainer=$ProjectName+"_pollingtentacle_1";
$OctopusDBContainer=$ProjectName+"_db_1";

Wait-ForServiceToPassHealthCheck $OctopusDBContainer
Wait-ForServiceToPassHealthCheck $OctopusServerContainer
Wait-ForServiceToPassHealthCheck $OctopusListeningTentacleContainer
Wait-ForServiceToPassHealthCheck $OctopusPollingTentacleContainer

Check-IPAddress

Write-DebugInfo @($OctopusDBContainer, $OctopusServerContainer, $OctopusListeningTentacleContainer, $OctopusPollingTentacleContainer)

Copy-FilesToDockerContainer "$PSScriptRoot/../tests/scripts/" $OctopusServerContainer
Copy-FilesToDockerContainer "$PSScriptRoot/../tests/scripts/" $OctopusListeningTentacleContainer
Copy-FilesToDockerContainer "$PSScriptRoot/../tests/scripts/" $OctopusPollingTentacleContainer

Start-TeamCityBlock "docker exec run-tests.ps1"
if (Test-Path ENV:TEAMCITY_PROJECT_NAME) {
  write-host "docker exec $OctopusServerContainer powershell -file /run-tests.ps1 -testfile octopus-server_spec.rb"
  & docker exec --env tc_project_name=$ENV:TEAMCITY_PROJECT_NAME $OctopusServerContainer powershell -file c:\run-tests.ps1 -testfile octopus-server_spec.rb
  write-host "docker exec $OctopusListeningTentacleContainer powershell -file /run-tests.ps1 -testfile octopus-listeningtentacle_spec.rb"
  & docker exec --env tc_project_name=$ENV:TEAMCITY_PROJECT_NAME $OctopusListeningTentacleContainer powershell -file c:\run-tests.ps1 -testfile listeningtentacle_spec.rb
  write-host "docker exec $OctopusPollingTentacleContainer powershell -file /run-tests.ps1 -testfile octopus-pollingtentacle_spec.rb"
  & docker exec --env tc_project_name=$ENV:TEAMCITY_PROJECT_NAME $OctopusPollingTentacleContainer powershell -file c:\run-tests.ps1 -testfile pollingtentacle_spec.rb
} else {
  write-host "docker exec $OctopusServerContainer powershell -file /run-tests.ps1 -testfile octopus-server_spec.rb"
  & docker exec $OctopusServerContainer powershell -file c:\run-tests.ps1 -testfile octopus-server_spec.rb
  write-host "docker exec $OctopusListeningTentacleContainer powershell -file /run-tests.ps1 -testfile octopus-listeningtentacle_spec.rb"
  & docker exec $OctopusListeningTentacleContainer powershell -file c:\run-tests.ps1 -testfile listeningtentacle_spec.rb
  write-host "docker exec $OctopusPollingTentacleContainer powershell -file /run-tests.ps1 -testfile octopus-pollingtentacle_spec.rb"
  & docker exec $OctopusPollingTentacleContainer powershell -file c:\run-tests.ps1 -testfile pollingtentacle_spec.rb
}
Stop-TeamCityBlock "docker exec run-tests.ps1"

Stop-TeamCityBlock "Run tests"
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

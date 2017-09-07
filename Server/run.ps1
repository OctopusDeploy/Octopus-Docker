param (
  [Parameter(Mandatory=$false)]
  [string]$ProjectName="octopusdocker"
)

. ../Scripts/build-common.ps1

$OctopusServerContainer=$ProjectName+"_octopus_1";
$OctopusDBContainer=$ProjectName+"_db_1";

Wait-ForServiceToPassHealthCheck $OctopusDBContainer
Wait-ForServiceToPassHealthCheck $OctopusServerContainer

Check-IPAddress

Write-DebugInfo @($OctopusDBContainer, $OctopusServerContainer)

write-host "-----------------------------------"
write-host "Copying test files"
Copy-FileToDockerContainer "$PSScriptRoot/../scripts/run-tests.ps1" "c:\run-tests.ps1"
Copy-FileToDockerContainer "$PSScriptRoot/../scripts/octopus-server_spec.rb" "c:\octopus-server_spec.rb"
Copy-FileToDockerContainer "$PSScriptRoot/../scripts/Gemfile" "c:\Gemfile"
Copy-FileToDockerContainer "$PSScriptRoot/../scripts/Gemfile.lock" "c:\Gemfile.lock"
Copy-FileToDockerContainer "$PSScriptRoot/../scripts/spec_helper.rb" "c:\spec_helper.rb"

write-host "-----------------------------------"
write-host "docker exec $OctopusServerContainer powershell -file /run-tests.ps1"
if (Test-Path ENV:TEAMCITY_PROJECT_NAME) {
  & docker exec --env tc_project_name=$ENV:TEAMCITY_PROJECT_NAME $OctopusServerContainer powershell -file c:\run-tests.ps1
} else {
  & docker exec $OctopusServerContainer powershell -file c:\run-tests.ps1
}
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}
write-host "-----------------------------------"

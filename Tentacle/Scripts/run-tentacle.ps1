[CmdletBinding()]
Param()

. ./octopus-common.ps1

function EnsureNotRunningAlready() {
   Stop-Process -name "Tentacle" -Force -ErrorAction SilentlyContinue
}

function Run-OctopusDeployTentacle
{
  if(!(Test-Path $TentacleExe)) {
    throw "File not found. Expected to find '$TentacleExe' to perform setup."
  }

  "Run started." | Set-Content "c:\octopus-run.initstate"

  & $TentacleExe run --noninteractive --instance 'Tentacle' --console

  Write-Log ""
}

try
{
  Write-Log "==============================================="
  Write-Log "Running Octopus Deploy Tentacle"
  Write-Log "==============================================="

  EnsureNotRunningAlready #Required since Windows Containers doesnt support sigterm signal on stop
  Run-OctopusDeployTentacle

  Write-Log "Run successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}

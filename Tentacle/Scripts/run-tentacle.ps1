[CmdletBinding()]
Param()

. ./octopus-common.ps1

function Deregister-Machine(){
  Write-Log "Deregistering Octopus Deploy Tentacle with server ..."
  $arg=@(
    'deregister-from',
    '--console',
    '--instance', 'Tentacle',
  '--server', $ServerUrl
  );
  if(!($ServerApiKey -eq $null)) {
    Write-Verbose "Registering Tentacle with api key"
    $arg += "--apiKey";
    $arg += $ServerApiKey
  } else {
    Write-Verbose "Registering Tentacle with username/password"
    $arg += "--username";
    $arg += $ServerUsername
    $arg += "--password";
    $arg += $ServerPassword
  }
  Execute-Command $TentacleExe, $arg
}

function EnsureNotRunningAlready() {
   Stop-Process -name "Tentacle" -Force -ErrorAction SilentlyContinue
}

function Run-OctopusDeployTentacle
{
 if(!(Test-Path $TentacleExe)) {
  throw "File not found. Expected to find '$TentacleExe' to perform setup."
  }

  "Run started." | Set-Content "c:\octopus-run.initstate"

  & $TentacleExe run --instance 'Tentacle' --console

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

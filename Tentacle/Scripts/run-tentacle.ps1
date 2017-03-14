[CmdletBinding()]
Param()

. ./octopus-common.ps1

function Deregister-Machine(){
  Write-Log "Deregistering Octopus Deploy Tentacle with server ..."
  $argz=@(
    'deregister-from',
    '--console',
    '--instance', 'Tentacle',
	'--server', $ServerUrl
  );
  if(!($ServerApiKey -eq $null)) {
		Write-Verbose "Registering Tentacle with api key"
		$argz += "--apiKey";
		$argz += $ServerApiKey
	} else {
		Write-Verbose "Registering Tentacle with username/password"
		$argz += "--username";
		$argz += $ServerUsername
		$argz += "--password";
		$argz += $ServerPassword
	}
  Execute-Command $TentacleExe, $argz
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

  Run-OctopusDeployTentacle

  Write-Log "Run successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}

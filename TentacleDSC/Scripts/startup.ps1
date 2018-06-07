[CmdletBinding()]
Param()

. ./common.ps1

. /3-DSC.ps1



function Export-MasterKey {
	#Write-Log "Writing MasterKey to C:\MasterKey\$env:OCTOPUS_INSTANCENAME"
  
	if($env:MasterKey -eq $null) {
		Write-Log "==============================================="
		Write-Log "Octopus Deploy Master Key"
		Write-Log "==============================================="
	  
		& $octopusServerExePath show-master-key --instance $env:OCTOPUS_INSTANCENAME
		Write-Log "==============================================="
		Write-Log ""
	}
}

function Run-OctopusDeploy
{

  Write-Log "Start Octopus Deploy instance ..."
  "Run started." | Set-Content "c:\octopus-run.initstate"

  & $octopusServerExePath run --instance $env:OCTOPUS_INSTANCENAME --console

  Write-Log ""
}

function EnsureNotRunningAlready() {
   Stop-Process -name "Octopus.Server" -Force -ErrorAction SilentlyContinue
}

try
{
  Write-Log "==============================================="
  Write-Log "Running Octopus Deploy"
  Write-Log "==============================================="

  
  #EnsureNotRunningAlready
  #Export-MasterKey
  #Run-OctopusDeploy

  Write-Log "Run successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}
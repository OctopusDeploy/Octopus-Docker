[CmdletBinding()]
Param()

. ./common.ps1

$octopusServerExePath="$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe"

. /3-DSC.ps1


<#
function Process-Import() {
 if(Test-Path 'C:\Import\metadata.json' ){

    $importPassword = $env:ImportPassword
    if($importPassword -eq $null) {
       $importPassword = 'blank';
    }


   Write-Log "Running Migrator import on C:\Import directory ..."
    $args = @(
    'import',
    '--console',
    '--directory',
    'C:\Import',
    '--instance',
    'OctopusServer',
    '--password',
    $importPassword
    )
    Execute-Command $MigratorExe $args
 }
}#>

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

  
  EnsureNotRunningAlready
  #Process-Import
  Export-MasterKey
  Run-OctopusDeploy

  Write-Log "Run successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}
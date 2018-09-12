[CmdletBinding()]
Param()

. ../octopus-common.ps1

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
}

function Run-OctopusDeploy
{

  Write-Log "Start Octopus Deploy instance ..."
  "Run started." | Set-Content "c:\octopus-run.initstate"

  & $ServerExe run --instance 'OctopusServer' --noninteractive

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
  Process-Import
  Run-OctopusDeploy

  Write-Log "Run successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}

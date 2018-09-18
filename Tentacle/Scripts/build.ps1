$Installer="Tentacle"

. ./common.ps1
. ./installers.ps1

function Configure-OctopusDeploy
{
  Write-Log "Configure Octopus Deploy Tentacle"

  if(!(Test-Path $Exe)) {
	throw "File not found. Expected to find '$Exe' to perform setup."
  }

  Write-Log "Creating Octopus Deploy Tentacle instance ..."
  $args = @(
    'create-instance',
    '--console',
    '--instance', 'Tentacle',
    '--config', 'C:\Octopus\Tentacle.config'
  )
  Execute-Command $Exe $args

  Write-Log ""
}


try
{
  Write-Log "==============================================="
  Write-Log "Installing $Msi version '$version'"
  Write-Log "==============================================="

  Stage-Installer
  Install-OctopusDeploy
  Delete-InstallLocation

  "Msi Install complete." | Set-Content "c:\octopus-install.initstate"

  Configure-OctopusDeploy

  exit 0
}
catch
{
  Write-Log $_
  exit 2
}
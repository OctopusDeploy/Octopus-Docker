$Installer="Octopus.Server"

. ./common.ps1
. ./installers.ps1

try
{
  Write-Log "==============================================="
  Write-Log "Installing $Msi version '$version'"
  Write-Log "==============================================="

  Stage-Installer
  Install-OctopusDeploy
  Delete-InstallLocation

"Msi Install complete." | Set-Content "c:\octopus-install.initstate"

# Configure-OctopusDeploy-Server
# Remove-MasterKey
   
  
  exit 0
}
catch
{
  Write-Log $_
  exit 2
}


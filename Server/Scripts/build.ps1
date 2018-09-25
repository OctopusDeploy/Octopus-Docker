$Installer="Octopus.Server"


. ./common.ps1
. ./installers.ps1

function Configure-Server(){
  Write-Log "Creating Octopus Deploy instance ..."
  Execute-Command $Exe @(
      'create-instance',
      '--console',
      '--instance', $OctopusInstanceName,
      '--config', 'C:\Octopus\OctopusServer.config'
  )
}

function Move-Logs(){
  Write-Log "Moving Octopus server logs to temporary location"
  # Move the log files away so that it can be mounted. The files will be added back during run phase
  # Mounting windows containers requires the volumes to be empty
  # https://github.com/docker/for-win/issues/644
  mv C:\Octopus\Logs C:\Octopus\LogsTemp
  Write-Log "moved"
}

try
{
  Write-Log "==============================================="
  Write-Log "Installing $Msi version '$version'"
  Write-Log "==============================================="

  Stage-Installer
  Install-OctopusDeploy
  Delete-InstallLocation
  Configure-Server
  Move-Logs
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


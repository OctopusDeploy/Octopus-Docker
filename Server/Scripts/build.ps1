$Installer="Octopus.Server"

. ./common.ps1
. ./installers.ps1

# function Remove-MasterKey
# {
#   $configFile = "C:\Octopus\OctopusServer.config"
#   [xml]$xml = Get-Content $configFile

#   $node = $xml.SelectSingleNode("//octopus-settings/set[@key='Octopus.Storage.MasterKey']")
#   if ($node -ne $null) {
#       $node.ParentNode.RemoveChild($node) | Out-Null
#   }

#   $xml.save($configFile)
# }

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


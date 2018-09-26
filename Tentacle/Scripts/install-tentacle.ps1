# [CmdletBinding()]
# Param()

# $Installer="Tentacle"
# . ./common.ps1


# $version = $env:OctopusVersion
# $msiFileName = "Octopus.Tentacle.$($version)-x64.msi"
# $downloadUrl = "https://download.octopusdeploy.com/octopus/" + $msiFileName
# $downloadUrlLatest = "https://octopusdeploy.com/downloads/latest/OctopusTentacle"
# #http://octopusdeploy.com/downloads/latest/OctopusTentacle

# $installBasePath = "C:\Install\"
# $msiPath = $installBasePath + $msiFileName
# $msiLogPath = $installBasePath + $msiFileName + '.log'
# $installerLogPath = $installBasePath + 'Install-OctopusDeploy.ps1.log'
# $OFS = "`r`n"

# . ./octopus-common.ps1

# function Create-InstallLocation
# {
#   Write-Log "Create Install Location"

#   if (!(Test-Path $installBasePath))
#   {
#     Write-Log "Creating installation folder at '$installBasePath' ..."
#     New-Item -ItemType Directory -Path $installBasePath | Out-Null
#     Write-Log "done."
#   }
#   else
#   {
#     Write-Log "Installation folder at '$installBasePath' already exists."
#   }

#   Write-Log ""
# }

# function Delete-InstallLocation
# {
#   Write-Log "Delete ./Installers Directory"
#   if (!(Test-Path "./Installers"))
#   {
#     Write-Log "Installers directory didn't exist - skipping delete"
#   }
#   else
#   {
#     Remove-Item "./Installers" -Recurse -Force
#   }
#   Write-Log ""


#   Write-Log "Delete Install Location"
#   if (!(Test-Path $installBasePath))
#   {
#     Write-Log "Install location didn't exist - skipping delete"
#   }
#   else
#   {
#     Remove-Item $installBasePath -Recurse -Force
#   }
#   Write-Log ""
# }

# function Configure-OctopusDeploy
# {
#   Write-Log "Configure Octopus Deploy Tentacle"

#   if(!(Test-Path $TentacleExe)) {
#   throw "File not found. Expected to find '$TentacleExe' to perform setup."
#   }

#   Write-Log "Creating Octopus Deploy Tentacle instance ..."
#   $args = @(
#     'create-instance',
#     '--console',
#     '--instance', 'Tentacle',
#     '--config', $TentacleConfig
#   )
#   Execute-Command $TentacleExe $args

#   Write-Log ""
# }

# try
# {
#   Write-Log "==============================================="
#   Write-Log "Configuring Octopus Deploy Tentacle version '$version'"
#   Write-Log "==============================================="

#   Configure-OctopusDeploy

#   "Install complete." | Set-Content "c:\octopus-install.initstate"

#   Write-Log "Configuration successful."
#   Write-Log ""
#   exit 0
# }
# catch
# {
#   Write-Log $_
#   exit 2
# }

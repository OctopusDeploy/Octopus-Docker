[CmdletBinding()]
Param()

$version = $env:OctopusVersion
$msiFileName = "Octopus.$($version)-x64.msi"
$downloadBaseUrl = "https://download.octopusdeploy.com/octopus/"
$downloadUrl = $downloadBaseUrl + $msiFileName
$installBasePath = "C:\Install\"
$msiPath = $installBasePath + $msiFileName
$msiLogPath = $installBasePath + $msiFileName + '.log'
$installerLogPath = $installBasePath + 'Install-OctopusDeploy.ps1.log'
$port=81
$listenPort=10943
$webListenPrefixes = "http://localhost:$port"

. ../octopus-common.ps1

function Configure-OctopusDeploy() {
  Write-Log "Configure Octopus Deploy"

  if(!(Test-Path $ServerExe)) {
    throw "File not found. Expected to find '$exe' to perform setup."
  }

  Write-Log "Creating Octopus Deploy instance ..."
  $args = @(
    'create-instance',
    '--console',
    '--instance', 'OctopusServer',
    '--config', 'C:\Octopus\OctopusServer.config'
  )
  Execute-Command $ServerExe $args

  Write-Log "Configuring Octopus Deploy instance ..."
  $args = @(
    'configure',
    '--console',
    '--instance', 'OctopusServer',
    '--home', 'C:\Octopus',
    '--upgradeCheck', 'True',
    '--upgradeCheckWithStatistics', 'True',
    '--webForceSSL', 'False',
    '--webListenPrefixes', $webListenPrefixes,
    '--commsListenPort', $listenPort
  )
  Execute-Command $ServerExe $args

  Write-Log ""
}

function Remove-MasterKey
{
  $configFile = "C:\Octopus\OctopusServer.config"
  [xml]$xml = Get-Content $configFile

  $node = $xml.SelectSingleNode("//octopus-settings/set[@key='Octopus.Storage.MasterKey']")
  if ($node -ne $null) {
      $node.ParentNode.RemoveChild($node) | Out-Null
  }

  $xml.save($configFile)
}

function Move-ConfigToBackupLocation
{
  Copy-Item "c:\Octopus\OctopusServer.config" "c:\OctopusServer.config.orig"
  Remove-Item "c:\Octopus\OctopusServer.config"
}

try
{
  Write-Log "==============================================="
  Write-Log "Configuring Octopus Server '$version'"
  Write-Log "==============================================="

  Configure-OctopusDeploy
  Remove-MasterKey            # removes the masterkey so that when a new instance is launched, it will get a new key
  Move-ConfigToBackupLocation # work around https://github.com/docker/docker/issues/20127

  "Server Install Complete." | Set-Content "c:\octopus-install.initstate"

  Write-Log "Configuration successful."
  Write-Log ""
  exit 0
}
catch
{
  Write-Log $_
  exit 2
}

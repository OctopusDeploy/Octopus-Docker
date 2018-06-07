[CmdletBinding()]
Param()

$version = $env:OctopusVersion
$msiFileName = "Octopus.Tentacle.$($version)-x64.msi"
$downloadUrl = "https://download.octopusdeploy.com/octopus/" + $msiFileName
$downloadUrlLatest = "https://octopusdeploy.com/downloads/latest/OctopusTentacle"
#http://octopusdeploy.com/downloads/latest/OctopusTentacle

$installBasePath = "C:\Install\"
$msiPath = $installBasePath + $msiFileName
$msiLogPath = $installBasePath + $msiFileName + '.log'
$installerLogPath = $installBasePath + 'Install-OctopusDeploy.ps1.log'
$OFS = "`r`n"

. ./octopus-common.ps1

function Create-InstallLocation
{
  Write-Log "Create Install Location"

  if (!(Test-Path $installBasePath))
  {
    Write-Log "Creating installation folder at '$installBasePath' ..."
    New-Item -ItemType Directory -Path $installBasePath | Out-Null
    Write-Log "done."
  }
  else
  {
    Write-Log "Installation folder at '$installBasePath' already exists."
  }

  Write-Log ""
}

function Delete-InstallLocation
{
  Write-Log "Delete ./Installers Directory"
  if (!(Test-Path "./Installers"))
  {
    Write-Log "Installers directory didn't exist - skipping delete"
  }
  else
  {
    Remove-Item "./Installers" -Recurse -Force
  }
  Write-Log ""


  Write-Log "Delete Install Location"
  if (!(Test-Path $installBasePath))
  {
    Write-Log "Install location didn't exist - skipping delete"
  }
  else
  {
    Remove-Item $installBasePath -Recurse -Force
  }
  Write-Log ""
}

function Stage-Installer {
  Write-Log "Stage Octopus Deploy Installer"
  $embeddedPath=[System.IO.Path]::Combine("/Installers",$msiFileName);
  if (Test-Path $embeddedPath) {

    Write-Log "Found correct version Octopus Deploy installer at '$embeddedPath'. Copying to '$msiPath' ..."
    Copy-Item $embeddedPath $msiPath
    Write-Log "done."
  }
  else {
    if($version -eq $null){
      $downloadUrl = $downloadUrlLatest
      Write-Log "No version specified for install. Using latest";
    }
    Write-Log "Downloading Octopus Deploy installer '$downloadUrl' to '$msiPath' ..."
    (New-Object Net.WebClient).DownloadFile($downloadUrl, $msiPath)
    Write-Log "done."
  }
}

function Install-OctopusDeploy
{
  Write-Log "Install Octopus Deploy  Tentacle"
  Write-Verbose "Starting MSI Installer"
  $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $msiPath /qn /l*v $msiLogPath" -Wait -Passthru).ExitCode
  Write-Verbose "MSI installer returned exit code $msiExitCode"
  if ($msiExitCode -ne 0) {
    Write-Verbose "-------------"
    Write-Verbose "MSI Log file:"
    Write-Verbose "-------------"
    Get-Content $msiLogPath
    Write-Verbose "-------------"
    throw "Install of Octopus Server failed, MSIEXEC exited with code: $msiExitCode. View the log at $msiLogPath"
  }
}

function Configure-OctopusDeploy
{
  Write-Log "Configure Octopus Deploy Tentacle"

  if(!(Test-Path $TentacleExe)) {
  throw "File not found. Expected to find '$TentacleExe' to perform setup."
  }

  Write-Log "Creating Octopus Deploy Tentacle instance ..."
  $args = @(
    'create-instance',
    '--console',
    '--instance', 'Tentacle',
    '--config', $TentacleConfig
  )
  Execute-Command $TentacleExe $args

  Write-Log ""
}

function Move-ConfigToBackupLocation
{
  Copy-Item $TentacleConfig $TentacleConfigTemp
  Remove-Item $TentacleConfig
}

try
{
  Write-Log "==============================================="
  Write-Log "Configuring Octopus Deploy Tentacle version '$version'"
  Write-Log "==============================================="

  Configure-OctopusDeploy
  Move-ConfigToBackupLocation # work around https://github.com/docker/docker/issues/20127

  "Install complete." | Set-Content "c:\octopus-install.initstate"

  Write-Log "Configuration successful."
  Write-Log ""
  exit 0
}
catch
{
  Write-Log $_
  exit 2
}

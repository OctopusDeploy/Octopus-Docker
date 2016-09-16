$version = $env:OctopusVersion
$msiFileName = "Octopus.$($version)-x64.msi"
$downloadBaseUrl = "https://download.octopusdeploy.com/octopus/"
$downloadUrl = $downloadBaseUrl + $msiFileName
$installBasePath = "C:\Install\"
$msiPath = $installBasePath + $msiFileName
$msiLogPath = $installBasePath + $msiFileName + '.log'
$installerLogPath = $installBasePath + 'Install-OctopusDeploy.ps1.log'
$port = 81
$webListenPrefixes = "http://localhost:$port"
$OFS = "`r`n"


function Write-Log
{
  param (
    [string] $message
  )

  $timestamp = ([System.DateTime]::UTCNow).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss")
  Write-Output "[$timestamp] $message"
}

function Execute-Command ($exe, $arguments)
{
  Write-Log "Executing command '$exe $($arguments -join ' ')'"
  $output = .$exe $arguments

  Write-CommandOutput $output
  if (($LASTEXITCODE -ne $null) -and ($LASTEXITCODE -ne 0)) {
    Write-Error "Command returned exit code $LASTEXITCODE. Aborting."
    exit 1
  }
  Write-Log "done."
}

function Write-CommandOutput
{
  param (
    [string] $output
  )

  if ($output -eq "") { return }

  Write-Output ""
  $output.Trim().Split("`n") |% { Write-Output "`t| $($_.Trim())" }
  Write-Output ""
}

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

function Install-OctopusDeploy
{
  Write-Log "Install Octopus Deploy"

  if (Test-Path "/source/*.msi") {
    if (Test-Path "/source/Octopus.Tentacle.*.msi") {
      Remove-Item "/source/Octopus.Tentacle.*.msi"
    }
    Write-Log "Copying Octopus Deploy installer from '/source/*.msi' to '$msiPath' ..."
    Copy-Item "/source/*.msi" $msiPath
    Write-Log "done."
  }
  else {
    Write-Log "Downloading Octopus Deploy installer '$downloadUrl' to '$msiPath' ..."
    (New-Object Net.WebClient).DownloadFile($downloadUrl, $msiPath)
    Write-Log "done."
  }

  Write-Log "Installing via '$msiPath' ..."
  $exe = 'msiexec.exe'
  $args = @(
    '/qn',
    '/i', $msiPath,
    '/l*v', $msiLogPath
  )
  Execute-Command $exe $args

  Write-Log ""
}

function Configure-OctopusDeploy
{
  Write-Log "Configure Octopus Deploy"

  $exe = 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe'

  $count = 0
  while(!(Test-Path $exe) -and $count -lt 10)
  {
    Write-Log "$exe - not available yet ... waiting 10s ..."
    Start-Sleep -s 10
    $count = $count + 1
  }

  if (!(Test-Path $exe)) {
    Write-Error "Octopus didn't install - waited $($count * 10) seconds for $exe to appear, but it didnt"
    exit 2
  }

  Write-Log "Creating Octopus Deploy instance ..."
  $args = @(
    'create-instance',
    '--console',
    '--instance', 'OctopusServer',
    '--config', 'C:\Octopus\OctopusServer.config'
  )
  Execute-Command $exe $args

  Write-Log "Configuring Octopus Deploy instance ..."
  $args = @(
    'configure',
    '--console',
    '--instance', 'OctopusServer',
    '--home', 'C:\Octopus',
    '--upgradeCheck', 'True',
    '--upgradeCheckWithStatistics', 'True',
    '--webAuthenticationMode', 'UsernamePassword',
    '--webForceSSL', 'False',
    '--webListenPrefixes', $webListenPrefixes,
    '--commsListenPort', '10943'
  )
  Execute-Command $exe $args

  Write-Log "Stopping Octopus Deploy instance ..."
  $args = @(
    'service',
    '--console',
    '--instance', 'OctopusServer',
    '--stop'
  )
  Execute-Command $exe $args
  
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
  Write-Log "Installing Octopus Deploy version '$version'"
  Write-Log " - downloading from '$downloadUrl'"
  Write-Log "==============================================="

  Write-Log "Installing '$msiFileName'"
  Write-Log ""

  Create-InstallLocation
  Install-OctopusDeploy
  Configure-OctopusDeploy
  Remove-MasterKey            # removes the masterkey so that when a new instance is launched, it will get a new key
  Delete-InstallLocation      # removes files we dont need to save space in the image
  Move-ConfigToBackupLocation # work around https://github.com/docker/docker/issues/20127

  "Install complete." | Set-Content "c:\octopus-install.initstate"

  Write-Log "Installation successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}

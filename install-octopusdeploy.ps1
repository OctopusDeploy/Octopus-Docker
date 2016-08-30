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

Write-Output "Installing Octopus Deploy version '$version'"
Write-Output " - downloading from '$downloadUrl'"
Write-Output "==============================================="

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
  Write-Log "======================================"
  Write-Log " Create Install Location"
  Write-Log ""

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

function Install-OctopusDeploy
{
  Write-Log "======================================"
  Write-Log " Install Octopus Deploy"
  Write-Log ""

  if (Test-Path "/source/$msiFileName") {
    Write-Log "Copying Octopus Deploy installer from '/source/$msiFileName' to '$msiPath' ..."
    Copy-Item "/source/$msiFileName" $msiPath
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
  Write-Log "======================================"
  Write-Log " Configure Octopus Deploy"
  Write-Log ""

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

try
{
  Write-Log "======================================"
  Write-Log " Installing '$msiFileName'"
  Write-Log "======================================"
  Write-Log ""

  Create-InstallLocation
  Install-OctopusDeploy
  Configure-OctopusDeploy

  Write-Log "Installation successful."
  Write-Log ""
}
catch
{
  Write-Log $_
}

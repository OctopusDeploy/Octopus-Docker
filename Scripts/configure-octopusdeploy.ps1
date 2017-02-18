$OFS = "`r`n"
$sqlDbConnectionString=$env:sqlDbConnectionString
$masterKey=$env:masterKey
$octopusAdminUsername=$env:OctopusAdminUsername
$octopusAdminPassword=$env:OctopusAdminPassword

$configFile = "c:\Octopus\OctopusServer.config"

function Write-Log
{
  param (
    [string] $message
  )

  $timestamp = ([System.DateTime]::UTCNow).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss")
  Write-Verbose "[$timestamp] $message"
}

function Execute-Command ($exe, $arguments)
{
  Write-Log (("Executing command '$exe $($arguments -join ' ')'") -replace "password=.*?;", "password=###########;")
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

  Write-Verbose ""
  $output.Trim().Split("`n") |% { Write-Verbose "`t| $($_.Trim())" }
  Write-Verbose ""
}

function Configure-OctopusDeploy
{
  $exe = 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe'

  $configAlreadyExists = Test-Path $configFile
  $masterKeySupplied = ($masterKey -ne $null) -and ($masterKey -ne "")
  if (-not($configAlreadyExists)) {
    # work around https://github.com/docker/docker/issues/20127
    Copy-item "c:\OctopusServer.config.orig" $configFile
  }

  Write-Log "Configuring Octopus Deploy instance ..."
  $args = @(
    'configure',
    '--console',
    '--instance', 'OctopusServer',
    '--home', 'C:\Octopus',
    '--storageConnectionString', $sqlDbConnectionString
  )
  if ($masterKeySupplied -and (-not ($configAlreadyExists))) {
    $args += '--masterkey'
    $args += $masterKey
  }
  Execute-Command $exe $args

  Write-Log "Creating Octopus Deploy database ..."
  $args = @(
    'database',
    '--console',
    '--instance', 'OctopusServer',
    '--create'
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

  Write-Log "Creating Admin User for Octopus Deploy instance ..."
  $args = @(
    'admin',
    '--console',
    '--instance', 'OctopusServer',
    '--username', $octopusAdminUserName,
    '--password', $octopusAdminPassword
  )
  Execute-Command $exe $args

  Write-Log "Configuring Octopus Deploy instance to use free license ..."
  $args = @(
    'license',
    '--console',
    '--instance', 'OctopusServer',
    '--free'
  )
  Execute-Command $exe $args

  if (($masterKey -eq $null) -or ($masterKey -eq "")) {
      Write-Log "Display master key ..."
      $args = @(
        'show-master-key',
        '--console',
        '--instance', 'OctopusServer'
      )
      Execute-Command $exe $args
  }

  Write-Log ""
}

try
{
  $maskedConnectionString = $sqlDbConnectionString -replace "password=.*?;", "password=###########;"
  Write-Log "==============================================="
  Write-Log "Configuring Octopus Deploy"
  Write-Log " - using database '$maskedConnectionString'"
  Write-Log " - local admin user '$octopusAdminUsername'"
  Write-Log " - local admin password '##########'"
  $masterKeySupplied = ($masterKey -ne $null) -and ($masterKey -ne "")
  if ((Test-Path $configFile) -and $masterKeySupplied) {
    Write-Log " - masterkey supplied, but server has already been configured - ignoring"
  }
  elseif (Test-Path $configFile) {
    Write-Log " - using previously configured masterkey from $configFile"
  }
  elseif ($masterKeySupplied) {
    Write-Log " - masterkey '##########'"
  }
  else {
    Write-Log " - masterkey not supplied. A new key will be generated automatically"
  }

  Write-Log "==============================================="

  Configure-OctopusDeploy
  "Configuration complete." | Set-Content "c:\octopus-configuration.initstate"

  Write-Log "Configuration successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}

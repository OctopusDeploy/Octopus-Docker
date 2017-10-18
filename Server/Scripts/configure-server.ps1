[CmdletBinding()]
Param()

. ../octopus-common.ps1

function Test-OctopusVersionRequiresWebAuthenticationMode {
  return $version -lt (New-Object System.Version 3, 5, 0)
}

function Test-OctopusVersionRequiresConfigureBeforeDatabaseCreate {
  return $version -lt (New-Object System.Version 3, 14, 0)
}

function Test-OctopusVersionSupportsPathCommand {
  return $version -ge (New-Object System.Version 3, 0, 21)
}

function Configure-OctopusDeploy(){

  $configAlreadyExists = Test-Path $configFile

  if (-not($configAlreadyExists)) {
    # work around https://github.com/docker/docker/issues/20127
    Copy-item "c:\OctopusServer.config.orig" $configFile
  }

  if (Test-OctopusVersionRequiresConfigureBeforeDatabaseCreate) {
    Write-Log "Configuring Octopus Deploy instance ..."
    $args = @(
      'configure',
      '--console',
      '--instance', 'OctopusServer',
      '--home', 'C:\Octopus',
      '--storageConnectionString', $sqlDbConnectionString,
      '--webAuthenticationMode', 'UsernamePassword'
    )

    Execute-Command $ServerExe $args

    Write-Log "Creating Octopus Deploy database ..."
    $args = @(
      'database',
      '--console',
      '--instance', 'OctopusServer',
      '--create'
    )
    if ($masterKeySupplied -and (-not ($configAlreadyExists))) {
      $args += '--masterkey'
      $args += $masterKey
    }
    Execute-Command $ServerExe $args
  } else {
    Write-Log "Creating Octopus Deploy database ..."
    $args = @(
      'database',
      '--console',
      '--instance', 'OctopusServer',
      '--connectionString', $sqlDbConnectionString,
      '--create'
    )
    if ($masterKeySupplied -and (-not ($configAlreadyExists))) {
      $args += '--masterkey'
      $args += $masterKey
    }
    Execute-Command $ServerExe $args

    Write-Log "Configuring Octopus Deploy instance ..."
    $args = @(
      'configure',
      '--console',
      '--instance', 'OctopusServer',
      '--home', 'C:\Octopus',
      '--usernamePasswordIsEnabled', 'True' #this will only work from 3.5 and above
    )
    Execute-Command $ServerExe $args
  }

  Write-Log "Configuring Paths ..."
  if (Test-OctopusVersionSupportsPathCommand) {
    $args = @(
      'path',
      '--console',
      '--instance', 'OctopusServer',
      '--nugetRepository', 'C:\Repository',
      '--artifacts', 'C:\Artifacts',
      '--taskLogs', 'C:\TaskLogs'
    )
    Execute-Command $ServerExe $args
  } else {
    Write-Log "Octopus version $version does not support modifying paths (it was introduced in 3.0.21)"
  }

  Write-Log "Creating Admin User for Octopus Deploy instance ..."
  $args = @(
    'admin',
    '--console',
    '--instance', 'OctopusServer',
    '--username', $octopusAdminUserName,
    '--password', $octopusAdminPassword
  )
  Execute-Command $ServerExe $args

  Write-Log "Configuring Octopus Deploy instance to use free license ..."
  $args = @(
    'license',
    '--console',
    '--instance', 'OctopusServer',
    '--free'
  )
  Execute-Command $ServerExe $args

  if (($masterKey -eq $null) -or ($masterKey -eq "")) {
    Write-Log "Display master key ..."
    $args = @(
      'show-master-key',
      '--console',
      '--instance', 'OctopusServer'
    )
    Execute-Command $ServerExe $args
  }

  Write-Log ""
}

function Validate-Variables() {
  $masterKeySupplied = ($masterKey -ne $null) -and ($masterKey -ne "")
  if (Test-Path $configFile) {
    if ($masterKeySupplied) {
      Write-Log " - masterkey supplied, but server has already been configured - using previously configured masterkey from $configFile instead"

    } else {
      Write-Log " - using previously configured masterkey from $configFile"
    }
  }
  elseif ($masterKeySupplied) {
    Write-Log " - masterkey '##########'"
  }
  else {
    Write-Log " - masterkey not supplied. A new key will be generated automatically."
  }

  $maskedConnectionString = "$sqlDbConnectionString;" -replace "password=.*?;", "password=###########;"
  Write-Log " - using database '$maskedConnectionString'"
  Write-Log " - local admin user '$octopusAdminUsername'"
  Write-Log " - local admin password '##########'"
}

try
{
  #remove any pre-release suffixes - for our purposes, the major.minor.patch is sufficient
  $version = New-Object System.Version ($env:OctopusVersion -split '-')[0]
  $sqlDbConnectionString = $env:sqlDbConnectionString
  $masterKey = $env:masterKey
  $masterKeySupplied = ($masterKey -ne $null) -and ($masterKey -ne "")
  $octopusAdminUsername = $env:OctopusAdminUsername
  $octopusAdminPassword = $env:OctopusAdminPassword
  $configFile = "c:\Octopus\OctopusServer.config"

  Write-Log "==============================================="
  Write-Log "Configuring Octopus Deploy"
  if (Test-Path c:\octopus-configuration.initstate){
    Write-Verbose "This Server has already been initialized and registered so reconfiguration will be skipped."
    Write-Verbose "If you need to change the configuration, please start a new container"
    exit 0
  }

  Validate-Variables
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

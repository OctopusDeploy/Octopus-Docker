$OFS = "`r`n"
#hack workaround for docker bug https://github.com/docker/docker/issues/26178
$sqlDbConnectionString=$env:sqlDbConnectionString -replace '##equals##', '='
$masterKey=$env:masterKey -replace '##equals##', '='
$octopusAdminUsername=$env:OctopusAdminUsername
$octopusAdminPassword=$env:OctopusAdminPassword

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

function Configure-OctopusDeploy
{
  $exe = 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe'

  Write-Log "Configuring Octopus Deploy instance ..."
  $args = @(
    'configure',
    '--console',
    '--instance', 'OctopusServer',
    '--home', 'C:\Octopus',
    '--storageConnectionString', $sqlDbConnectionString
  )
  if ($masterKey -ne $null -and $masterKey -ne "") {
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
  Write-Log "==============================================="
  Write-Log "Running Octopus Deploy"
  Write-Log " - using database '$sqlDbConnectionString'"
  Write-Log " - local admin user '$octopusAdminUsername'"
  Write-Output " - local admin password '##########'"
  if (($masterKey -eq $null) -or ($masterKey -eq "")) {
    Write-Log " - masterkey not supplied."
    Write-Log "   WARNING: this means OctopusDeploy will use the masterkey that was generated when the image was created."
    Write-Log "            This key is common to all users of this image and therefore provides no security."
  }
  else {
    Write-Log " - masterkey '##########'"
  }

  Write-Log "==============================================="

  Configure-OctopusDeploy

  Write-Log "Configuration successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}

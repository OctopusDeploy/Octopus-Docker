$OFS = "`r`n"
#hack workaround for docker bug https://github.com/docker/docker/issues/26178
$sqlDbConnectionString=$env:sqlDbConnectionString -replace '##equals##', '='
$octopusAdminUsername=$env:OctopusAdminUsername
$octopusAdminPassword=$env:OctopusAdminPassword

Write-Output "Running Octopus Deploy"
Write-Output " - using database '$sqlDbConnectionString'"
Write-Output " - local admin user '$octopusAdminUsername'"
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

function Configure-OctopusDeploy
{
  Write-Log "======================================"
  Write-Log " Configure Octopus Deploy"
  Write-Log ""

  $exe = 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe'

  Write-Log "Configuring Octopus Deploy instance ..."
  $args = @(
    'configure',
    '--console',
    '--instance', 'OctopusServer',
    '--home', 'C:\Octopus',
    '--storageConnectionString', $sqlDbConnectionString
  )
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

  Write-Log "Start Octopus Deploy instance ..."
  $args = @(
    'service',
    '--console',
    '--instance', 'OctopusServer',
    '--install',
    '--reconfigure',
    '--start'
  )
  Execute-Command $exe $args

  try {
     # sleep-loop indefinitely (until container stop)
     while (1 -eq 1) {
         [DateTime]::Now.ToShortTimeString()
         Start-Sleep -Seconds 1
     }
  } 
  finally {
      Write-Log "Shutting down Octopus Deploy instance ..."
      $args = @(
        'service',
        '--console',
        '--instance', 'OctopusServer',
        '--install',
        '--reconfigure',
        '--stop'
      )
      Execute-Command $exe $args
  }

  Write-Log ""
}

try
{
  Configure-OctopusDeploy

  Write-Log "Configuration successful."
  Write-Log ""
}
catch
{
  Write-Log $_
}

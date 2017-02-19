$OFS = "`r`n"

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

  Write-Verbose ""
  $output.Trim().Split("`n") |% { Write-Verbose "`t| $($_.Trim())" }
  Write-Verbose ""
}

function Run-OctopusDeploy
{
  $exe = 'C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe'

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

  "Run started." | Set-Content "c:\octopus-run.initstate"

  # try/finally is here to try and stop the server gracefully upon container stop
  try {
     # sleep-loop indefinitely (until container stop)
    $lastCheck = (Get-Date).AddSeconds(-2)
    while ($true) {
      Get-EventLog -LogName Application -Source "Octopus*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message
      $lastCheck = Get-Date
       "$([DateTime]::Now.ToShortTimeString()) - OctopusDeploy service is '$((Get-Service "OctopusDeploy").status)'."
       Start-Sleep -Seconds 60
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
  Write-Log "==============================================="
  Write-Log "Running Octopus Deploy"
  Write-Log "==============================================="

  Run-OctopusDeploy

  Write-Log "Run successful."
  Write-Log ""
}
catch
{
  Write-Log $_
  exit 2
}

[CmdletBinding()]
Param()

. ../octopus-common.ps1

function Run-OctopusDeploy
{

  Write-Log "Start Octopus Deploy instance ..."
  $args = @(
    'service',
    '--console',
    '--instance', 'OctopusServer',
    '--install',
    '--reconfigure',
    '--start'
  )
  Execute-Command $ServerExe $args

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
      Execute-Command $ServerExe $args
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

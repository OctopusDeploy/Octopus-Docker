$OFS = "`r`n";
$TentacleExe="C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe";
$TentacleConfig="C:\Octopus\Tentacle.config";
$TentacleConfigTemp="C:\Tentacle.config.orig"; # work around https://github.com/docker/docker/issues/20127
 
 $ServerExe="C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe";
 $MigratorExe="C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe";
 
function Write-Log
{
  param (
    [string] $message
  )

  $timestamp = ([System.DateTime]::UTCNow).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss")
  Write-Verbose "[$timestamp] $message"
}

function Execute-Command ($exe, $arguments, $mask)
{
  $maskedArgs = $($arguments -join ' ')
  if ($mask -ne $null) {
    $mask | % { $maskedArgs = $maskedArgs -replace [Regex]::Escape($_), "*****"}
  }
  Write-Log "Executing command '$exe $($maskedArgs -join ' ')'"
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

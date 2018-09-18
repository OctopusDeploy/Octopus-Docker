if ($Installer -eq "Octopus.Server") {
  $Exe="C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe"
  $Version=$env:OctopusVersion
  $DownloadUrlLatest='https://octopus.com/downloads/latest/WindowsX64/OctopusServer'
  $DownloadBaseUrl="http://10.0.75.1:8081/"#"https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/"
  $MsiFileName = "Octopus.$Version-x64.msi";
} elseif ($Installer -eq "Tentacle") {
  $Exe="C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe";
  $Version=$env:TentacleVersion
  $DownloadUrlLatest='https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle'
  $DownloadBaseUrl="http://10.0.75.1:8081/"#"https://s3-ap-southeast-1.amazonaws.com/octopus-testing/tentacle/"
  $MsiFileName = "Octopus.Tentacle.$Version-x64.msi";
} else {
  Write-Error "Unknown installer type"
  exit 1
}
$InstallBasePath = "C:\Install\"
$MsiPath = $InstallBasePath + $MsiFileName
$MigratorExe="C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe";

function Write-Log
{
  param (
    [string] $message
  )

  $timestamp = ([System.DateTime]::UTCNow).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss")
  Write-Host "[$timestamp] $message"
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
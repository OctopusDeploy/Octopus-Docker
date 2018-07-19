. ./common.ps1

$version = $env:TentacleVersion
$msiFileName = "Octopus.Tentacle.$($version)-x64.msi"
$installBasePath = "C:\Install\"
$msiPath = $installBasePath + $msiFileName
$msiLogPath = $installBasePath + $msiFileName + '.log'

function Get-DownloadUrl {
	$downloadUrlLatest = 'https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle'
	$downloadBaseUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/tentacle/" #"https://download.octopusdeploy.com/octopus/"


	if($env:DownloadUrl -ne $null){
		Write-Log "Download location provided as $env:DownloadUrl"
		return $env:DownloadUrl
	} elseif($version -eq $null) {
		Write-Log "No version specified for install. Using latest";
		return $downloadUrlLatest      
	} else {
		$downloadUrl = $downloadBaseUrl + $msiFileName
		Write-Log "Downloading msi from $downloadUrl"
		return $downloadUrl
	}
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


function Stage-Installer {
	
	
	$downloadUrl=Get-DownloadUrl
	 Write-Log "Downloading installer '$downloadUrl' to '$msiPath' ..."
	(New-Object Net.WebClient).DownloadFile($downloadUrl, $msiPath)
	 Write-Log "done."
}

function Install-OctopusDeploy
{
  Write-Log "Installing $msiFileName"
  Write-Verbose "Starting MSI Installer"
  $msiExitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $msiPath /qn /l*v $msiLogPath" -Wait -Passthru).ExitCode
  Write-Verbose "MSI installer returned exit code $msiExitCode"
  if ($msiExitCode -ne 0) {
    Write-Verbose "-------------"
    Write-Verbose "MSI Log file:"
    Write-Verbose "-------------"
    Get-Content $msiLogPath
    Write-Verbose "-------------"
    throw "Install of $Msi failed, MSIEXEC exited with code: $msiExitCode. View the log at $msiLogPath"
  }
}


function Delete-InstallLocation
{
  Write-Log "Delete Install Location"
  if (-not (Test-Path $installBasePath))
  {
    Write-Log "Install location didn't exist - skipping delete"
  }
  else
  {
    Get-ChildItem $installBasePath -Recurse | Remove-Item -Force
    Remove-Item $installBasePath -Recurse -Force
  }
  Write-Log ""
}


$TentacleExe="C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe";
$TentacleConfig="C:\Octopus\Tentacle.config";
$TentacleConfigTemp="C:\Tentacle.config.orig"; # work around https://github.com/docker/docker/issues/20127

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
  Write-Log "Configure Octopus Deploy Tentacle"

  if(!(Test-Path $TentacleExe)) {
	throw "File not found. Expected to find '$TentacleExe' to perform setup."
  }

  Write-Log "Creating Octopus Deploy Tentacle instance ..."
  $args = @(
    'create-instance',
    '--console',
    '--instance', 'Tentacle',
    '--config', $TentacleConfig
  )
  Execute-Command $TentacleExe $args

  Write-Log ""
}

try
{
  Write-Log "==============================================="
  Write-Log "Installing $Msi version '$version'"
  Write-Log "==============================================="

  Create-InstallLocation
  Stage-Installer
  Install-OctopusDeploy
  Delete-InstallLocation      # removes files we dont need to save space in the image

  "Msi Install complete." | Set-Content "c:\octopus-install.initstate"

   Configure-OctopusDeploy
   
 "Install complete." | Set-Content "c:\octopus-install.initstate"
   
  
  exit 0
}
catch
{
  Write-Log $_
  exit 2
}


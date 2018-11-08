$Installer="Octopus.Server"
$env:OCTOPUS_INSTANCENAME=$OctopusInstanceName
[System.Environment]::SetEnvironmentVariable("OCTOPUS_INSTANCENAME", $OctopusInstanceName, [System.EnvironmentVariableTarget]::User);

. ./common.ps1

  #remove any pre-release suffixes - for our purposes, the major.minor.patch is sufficient
  
  $sqlDbConnectionString = $env:sqlDbConnectionString
  $masterKey = $env:masterKey
  $masterKeySupplied = ($masterKey -ne $null) -and ($masterKey -ne "")
  $octopusAdminUsername = $env:OctopusAdminUsername
  $octopusAdminPassword = $env:OctopusAdminPassword
  $configFile = "c:\Octopus\OctopusServer.config"
  $ServerNodeName = $env:ServerNodeName
  
  $simpleVersion = New-Object System.Version ($Version -split '-')[0]
  function Test-OctopusVersionRequiresConfigureBeforeDatabaseCreate {
    return $simpleVersion -lt (New-Object System.Version 3, 14, 0)
  }
  function Test-OctopusVersionSupportsPathCommand {
    return $simpleVersion -ge (New-Object System.Version 3, 0, 21)
  }
  
function Validate-Variables() {
    # If no master key has been defined, we will create some default credentials
    if (-not $masterKeySupplied)
    {
      if ($octopusAdminUsername -eq $null)
      {
        $octopusAdminUsername = "admin"
      }
      if ($octopusAdminPassword -eq $null)
      {
        $octopusAdminPassword = "Passw0rd123"
      }
      Write-Log " - local admin user '$octopusAdminUsername'"
      Write-Log " - local admin password '##########'"
    }

    if($sqlDbConnectionString -eq $null){
        Write-Error "Environment variable sqlDbConnectionString required"
        Exit 2
    }
    $maskedConnectionString = "$sqlDbConnectionString;" -replace "password=.*?;", "password=###########;"
    Write-Log " - using database '$maskedConnectionString'"
  }

  function Move-Logs() {
    # Move the log files back in case it was mounted. The files were moved during the install phase
    # Mounting windows containers requires the volumes to be empty
    # https://github.com/docker/for-win/issues/644
    Write-Log "Moving Octopus configuration back from temporary location"
    if(!(Test-Path C:\Octopus\Logs)) {
      mkdir C:\Octopus\Logs | Out-Null
    }
    mv C:\Octopus\LogsTemp\* C:\Octopus\Logs
    Remove-Item C:\Octopus\LogsTemp -Recurse -Force
    Write-Log "moved"
  }

  function Configure-OctopusDeploy() {
    $port=81
    $listenPort=10943
    $webListenPrefixes = "http://localhost:$port"

    Write-Log "Configure Octopus Deploy"
    
    Write-Log "Configuring Octopus Deploy instance with default options ..."
    Execute-Command $Exe @(
        'configure',
        '--console',
        '--instance', $OctopusInstanceName,
        '--home', 'C:\Octopus',
        '--serverNodeName', $ServerNodeName,
        '--upgradeCheck', 'True',
        '--upgradeCheckWithStatistics', 'True',
        '--webForceSSL', 'False',
        '--webListenPrefixes', $webListenPrefixes,
        '--commsListenPort', $listenPort
      )

    if (Test-OctopusVersionRequiresConfigureBeforeDatabaseCreate) {
      Write-Log "Configuring Octopus Deploy instance ..."

      $args = @(
        'configure',
        '--console',
        '--instance', 'OctopusServer',
        '--storageConnectionString', $sqlDbConnectionString,
        '--webAuthenticationMode', 'UsernamePassword'
      )
      if (!$masterKeySupplied) {
        $args += '--webAuthenticationMode'
        $args += 'UsernamePassword'
      }
      Execute-Command $Exe $args
  
      Write-Log "Creating Octopus Deploy database ..."
      $args = @(
        'database',
        '--console',
        '--instance', 'OctopusServer',
        '--create'
      )
      if ($masterKeySupplied) {
        $args += '--masterkey'
        $args += $masterKey
      }
      Execute-Command $Exe $args $masterKey
    } else {
      Write-Log "Creating Octopus Deploy database ..."
      $args = @(
        'database',
        '--console',
        '--instance', $OctopusInstanceName,
        '--connectionString', $sqlDbConnectionString,
        '--create'
      )
      if ($masterKeySupplied) {
        $args += '--masterkey'
        $args += $masterKey
      }
      Execute-Command $Exe $args @($masterKey, $sqlDbConnectionString)
    }

    #TODO: Not sure this is helpful... if we cant set the path then it cant be mounted correctly...
    Write-Log "Configuring Paths ..."
    if (Test-OctopusVersionSupportsPathCommand) {
      Execute-Command $Exe @(
        'path',
        '--console',
        '--instance', $OctopusInstanceName,
        '--nugetRepository', 'C:\Repository',
        '--artifacts', 'C:\Artifacts',
        '--taskLogs', 'C:\TaskLogs'
      )
    } else {
      Write-Log "Octopus version $version does not support modifying paths (it was introduced in 3.0.21)"
    }
      
  
    if ($octopusAdminPassword -ne $null -or $octopusAdminUserName -ne $null) {
        Write-Log "Creating Admin User for Octopus Deploy instance ..."
        $args = @(
            'admin',
            '--console',
            '--instance', $OctopusInstanceName
        )
        if ($octopusAdminUserName) {
            $args += '--username'
            $args += $octopusAdminUserName
        }
        if ($octopusAdminPassword) {
            $args += '--password'
            $args += $octopusAdminPassword
        }
        Execute-Command $Exe $args $octopusAdminPassword

        Write-Log "Enabling Username and Password Auth ..."
        Execute-Command $Exe @(
          'configure',
          '--console',
          '--instance', $OctopusInstanceName,
          '--usernamePasswordIsEnabled', 'True' #this will only work from 3.5 and above
        )
    }

    if($env:LicenceBase64 -eq $null) {
      if (!$masterKeySupplied) {
        Write-Log "Configuring Octopus Deploy instance to use free license ..."
        Execute-Command $Exe @(
            'license',
            '--console',
            '--instance',$OctopusInstanceName,
            '--free'
          )
      }
    } else {
      Write-Log "Configuring Octopus Deploy instance to use provided license"
      Execute-Command $Exe @(
        'license',
        '--console',
        '--instance', $OctopusInstanceName,
        '--licenseBase64', $env:LicenceBase64
      )
    }
}


function Process-Import() {
  if(Test-Path 'C:\Import\metadata.json' ) {
 
     $importPassword = $env:ImportPassword
     if($importPassword -eq $null) {
        $importPassword = 'blank';
     }
 
 
    Write-Log "Running Migrator import on C:\Import directory ..."
     $args = @(
     'import',
     '--console',
     '--directory', 'C:\Import',
     '--instance', $OctopusInstanceName,
     '--password', $importPassword
     )
     Execute-Command $MigratorExe $args $importPassword
  }
 }

  function Run-OctopusDeploy
{

  Write-Log "Start Octopus Deploy instance ..."
  "Run started." | Set-Content "c:\octopus-run.initstate"

  & $Exe run --instance $OctopusInstanceName --noninteractive

  Write-Log ""
}

function Export-MasterKey {
  if(Test-Path "C:\MasterKey") {
    Write-Log "Writing MasterKey to C:\MasterKey\$OctopusInstanceName"
  
		Write-Log "==============================================="
		Write-Log "Writing Octopus Deploy Master Key to C:\MasterKey\$OctopusInstanceName"
		Write-Log "==============================================="
     
   (& $Exe show-master-key --instance $OctopusInstanceName) | Out-File C:\MasterKey\$OctopusInstanceName -NoNewline
		Write-Log "==============================================="
		Write-Log ""
	}
}

try
{
  Write-Log "==============================================="
  Write-Log "Configuring Octopus Deploy"
  if (Test-Path c:\octopus-configuration.initstate){
    Write-Verbose "This Server has already been initialized and registered so reconfiguration will be skipped."
    Write-Verbose "If you need to change the configuration, please start a new container"
    exit 0
  }

  Validate-Variables
  Write-Log "===============================================xxx"

  Move-Logs
  Configure-OctopusDeploy
  "Configuration complete." | Set-Content "c:\octopus-configuration.initstate"
  Export-MasterKey
  Write-Log "Configuration successful."
  
  Write-Log "==============================================="
  Write-Log "Running Octopus Deploy"
  Write-Log "==============================================="
  Process-Import
  #Run-OctopusDeploy
  Write-Log "Run successful."
  Write-Log ""

}
catch
{
  Write-Log $_
  exit 2
} #2018.8.6-robsremovegcserv0176

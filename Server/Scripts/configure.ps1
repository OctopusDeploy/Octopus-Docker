$Installer="Octopus.Server"
$env:OCTOPUS_INSTANCENAME=$OctopusInstanceName
[System.Environment]::SetEnvironmentVariable("OCTOPUS_INSTANCENAME", $OctopusInstanceName, [System.EnvironmentVariableTarget]::User);

. ./common.ps1
 
  $sqlDbConnectionString = $env:sqlDbConnectionString
  $masterKey = $env:masterKey
  $octopusAdminUsername = $env:OctopusAdminUsername
  $octopusAdminPassword = $env:OctopusAdminPassword
  $octopusAdminEmail = $env:OctopusAdminEmail
  

function Create-Instance() {
  Write-Log "Creating Octopus Deploy instance ..."
  Execute-Command $Exe @('create-instance', '--instance', $OctopusInstanceName, '--config', 'C:\Octopus\OctopusServer.config')
}

function Configure-Database() {
  if($null -eq $sqlDbConnectionString){
    Write-Error "Environment variable sqlDbConnectionString required"
    Exit 2
  }
  $maskedConnectionString = "$sqlDbConnectionString;" -replace "password=.*?;", "password=###########;"
  Write-Log " - using database '$maskedConnectionString'"
  Write-Log "Creating Octopus Deploy database ..."
  $args = @('database','--instance', $OctopusInstanceName, '--connectionString', $sqlDbConnectionString, '--create')
  if ($null -ne $masterKey) {
    $args += @('--masterkey', $masterKey)
  }
  Execute-Command $Exe $args @($masterKey, $sqlDbConnectionString)
  Export-MasterKey
}

function Configure-Paths() {
  Write-Log "Configuring Paths ..."
  Execute-Command $Exe @('path', '--instance', $OctopusInstanceName,
    '--nugetRepository', 'C:\Repository',
    '--artifacts', 'C:\Artifacts',
    '--taskLogs', 'C:\TaskLogs'
  )
}

function Configure-Node() {
  Write-Log "Configuring Octopus Deploy instance with default options ..."
  $args = @(
      'configure',
      '--instance', $OctopusInstanceName,
      '--upgradeCheck', 'True',
      '--webForceSSL', 'False',
      '--webListenPrefixes', "http://localhost:81",
      '--commsListenPort', 10943
    )

  if($env:EnableUsage -eq "Y" -or $env:EnableUsage -eq "y" ) {
    $args += @('--upgradeCheckWithStatistics', 'True')
  } else {
    $args += @('--upgradeCheckWithStatistics', 'False')
  }

  if($null -ne $env:ServerNodeName) {
    $args += @('--serverNodeName', $env:ServerNodeName)
  }
  
  Execute-Command $Exe $args

  if($env:EnableMetrics -eq "true") {
    Write-Log "Enabling metrics logging"
    Execute-Command $Exe @('metrics', '--instance', $OctopusInstanceName, '--enable', '--tasks', 'true', '--webapi', 'true')
  }
}

function Configure-Admin() {

    if(($null -eq $masterKey) -and ($null -eq $octopusAdminUsername)) {
      Write-Log "WARNING: No admin username provided, using default."
      $octopusAdminUsername="admin";
    }

    if(($null -eq $masterKey) -and ($null -eq $octopusAdminPassword)) {
      Write-Log "WARNING: No admin password provided, using default. It is HIGHLY recomended you change this on first login"
      $octopusAdminPassword="Passw0rd123";
    }

    if(($null -ne $octopusAdminPassword) -and ($null -eq $octopusAdminUsername)){
      Write-Log "ERROR: A new admin password was provided but no admin username was specified."
      exit 1
    }

    if($null -eq $octopusAdminUsername){
      Write-Log "no admin credentials provided. Will not update admin or re-enable usernamePassowrd auth"
      return;
    }

    if($null -eq $octopusAdminEmail){
      Write-Log "No email provided. Admin will be configured with octopus@example.local"
      $octopusAdminEmail="octopus@example.local"
    }

    Execute-Command $Exe @('admin', '--instance', $OctopusInstanceName, '--username', $octopusAdminUsername, '--email', $octopusAdminEmail, '--password', $octopusAdminPassword)

    # If you do not set the master key or supply the username and/or password, the user/pass
    # auth plugin is enabled.
    Write-Log "Enabling Username and Password Auth ..."
    Execute-Command $Exe @('configure', '--instance', $OctopusInstanceName, '--usernamePasswordIsEnabled', 'True')
}

function Configure-License() {
  if($null -ne $env:LicenceBase64) {
    Write-Log "Configuring Octopus Deploy instance to use provided license"
    Execute-Command $Exe @( 'license', '--instance', $OctopusInstanceName, '--licenseBase64', $env:LicenceBase64)
  } elseif ($null -eq $masterKey) {
      Write-Log "Configuring Octopus Deploy instance to use free license ..."
      Execute-Command $Exe @('license', '--instance',$OctopusInstanceName, '--free')
  }
}

function Process-Import() {
  if(Test-Path 'C:\Import\metadata.json' ) {
 
     $importPassword = $env:ImportPassword
     if($null -eq $importPassword) {
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

  function Run-OctopusDeploy {
  Write-Log "Start Octopus Deploy instance ..."
  "Run started." | Set-Content "c:\octopus-run.initstate"

  & $Exe run --instance $OctopusInstanceName --noninteractive
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


Write-Log "==============================================="
Write-Log "Configuring Octopus Deploy"
if (Test-Path c:\octopus-configuration.initstate){
  Write-Verbose "This Server has already been initialized and registered so reconfiguration will be skipped."
  Write-Verbose "If you need to change the configuration, please start a new container"
  exit 0
}

Create-Instance
Configure-Database
Configure-Node
Configure-Admin
Configure-Paths
Configure-License

"Configuration complete." | Set-Content "c:\octopus-configuration.initstate"
Write-Log "Configuration successful."
Write-Log "==============================================="
Write-Log "Running Octopus Deploy"
Write-Log "==============================================="
Process-Import
Run-OctopusDeploy
Write-Log "Run successful."
Write-Log ""
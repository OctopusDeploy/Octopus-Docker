$env:SA_PASSWORD="N0tS3cr3t!"
[System.Environment]::SetEnvironmentVariable("SA_PASSWORD", $env:SA_PASSWORD, [System.EnvironmentVariableTarget]::User)

$env:sqlDbConnectionString="Server=localhost,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=$($env:SA_PASSWORD);MultipleActiveResultSets=False;Connection Timeout=30;"
[System.Environment]::SetEnvironmentVariable("sqlDbConnectionString", $env:sqlDbConnectionString, [System.EnvironmentVariableTarget]::User)

./Server/build.ps1
if($LastExitCode -ne 0) {
    exit $last
}

./Combined/sql-express.ps1 -ACCEPT_EULA "Y" -sa_password $env:SA_PASSWORD -Verbose
if($LastExitCode -ne 0) {
    exit $last
}

./Server/configure.ps1
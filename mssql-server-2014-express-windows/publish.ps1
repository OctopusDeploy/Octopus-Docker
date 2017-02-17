param (
  [Parameter(Mandatory=$true)]
  [string]$UserName,
  [Parameter(Mandatory=$true)]
  [string]$Password
)

write-host "docker login -u=`"$UserName`" -p=`"#########`""
& docker login -u="$UserName" -p="$Password"
if ($$LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

write-host "docker push octopusdeploy/mssql-server-2014-express-windows:latest"
& docker push octopusdeploy/mssql-server-2014-express-windows:latest
exit $LASTEXITCODE

if (-not (Test-Path c:\sqlserver.initstate)) {
  Write-Output "SQL Server Express initialisation file (c:\sqlserver.initstate) does not yet exist"
  exit 1
}

$service = Get-Service "MSSQL`$SQLEXPRESS"
if ($service -eq $null) {
  Write-Output "SQL Server Express service (MSSQL`$SQLEXPRESS) not found"
  exit 2
}

if ($service.Status -ne 'Running') {
  Write-Output "SQL Server Express service (MSSQL`$SQLEXPRESS) is not 'running'"
  exit 3
}

Write-Output "SQL Server Express appears to be running okay"
exit 0
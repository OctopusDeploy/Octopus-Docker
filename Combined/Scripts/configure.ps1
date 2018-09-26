
#IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = 'foobar') BEGIN EXEC sp_detach_db [foobar] END;
#CREATE DATABASE [foobar] ON (FILENAME = N'C:\Temp\DB\OctoA.mdf'),  (FILENAME = N'C:\Temp\DB\OctoA.ldf')  FOR ATTACH;

#$env:DBFiles = @("C:\temp\perrytest.mdf","C:\temp\perrytest_log.ldf")
function Attach-DB() {
    param ([Parameter(Mandatory=$true)] [string]$DBFiles)
    
    if($DBFiles -eq $null) {
        Write-Host "No database files provided. Using existing empty instance"
        #Copy-Default
        return
    }

    $dbName="Octopus"
    $files = @();
    Foreach($file in $DBFiles)
    {
        $files += "(FILENAME = N'$($file)')";           
    }

    $files = $files -join ","
    $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '" + $dbName + "') BEGIN EXEC sp_detach_db [$dbName] END;CREATE DATABASE [$dbName] ON $($files) FOR ATTACH;"

    Write-Verbose "Invoke-Sqlcmd -Query $($sqlcmd)"
    & sqlcmd -Q $sqlcmd
}
#ForEach($r in $t){if($r[0] -eq "C"){Write-Host $r +"X"}}




function Update-SA() {
    if($env:sa_password -eq $null) {
        if($env:DBFiles -ne $null) {
            Write-Host "SA password has not been modified"
        }
        return
    }

    Write-Verbose "Changing SA login credentials"
    $sqlcmd = "ALTER LOGIN sa with password=" +"'" + $env:sa_password + "'" + ";ALTER LOGIN sa ENABLE;"
    & sqlcmd -Q $sqlcmd
}

function Copy-Default() {
    if((Test-Path C:\DB) -and ($env:DBFiles -eq $null)) {
        $dbName="octopus"

        $res=(sqlcmd -Q "select physical_name from [octopus].sys.database_files")
        sqlcmd -Q "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '" + $dbName + "') BEGIN EXEC sp_detach_db [$dbName] END;"
        stop-service MSSQL`$SQLEXPRESS


        ForEach($line in $res) { if($line[0] -eq 'C') {
            $file = $(Get-Item $line.Trim()).Name
            if(Test-Path C:\DB\$file) {
                Write-Host "DB file already exists at `C:\DB\Octopus.mdf`. This file will be attached as the Octopus database"
                rm $line.Trim()
            } else {
                mv $line.Trim() C:\DB
            }
        }       
    }
}

./Combined/sql-express.ps1 -ACCEPT_EULA "Y" -sa_password $env:SA_PASSWORD -Verbose

#Attach-DB
#Update-SA

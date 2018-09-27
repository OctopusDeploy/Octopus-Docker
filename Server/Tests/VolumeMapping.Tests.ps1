param(
    [ValidateNotNullOrEmpty()]
	[string]$OctopusUsername,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusPassword,
	[ValidateNotNullOrEmpty()]
	[string]$OctopusVersion
)
$IPAddress=$(Get-IPAddress)
$OctopusURI="http://$($IPAddress):81"

Describe 'Volume Mounts' {
	$endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
	$repository = new-object Octopus.Client.OctopusRepository $endpoint
	$LoginObj = New-Object Octopus.Client.Model.LoginCommand 
	$LoginObj.Username = $OctopusUsername
	$LoginObj.Password = $OctopusPassword
	$repository.Users.SignIn($LoginObj)
	
	<#
	Something randomly failing with this in TC... need to investigate
	Context 'C:\Packages' {
		it 'should have provided a package for the Server' {
			$task = New-Object  Octopus.Client.Model.TaskResource
			$task.Name = "SynchronizeBuiltInPackageRepositoryIndex"
			$task.Description = "Re-index built-in package repository"
			$task.State = [Octopus.Client.Model.TaskState]::Queued

			$Task1 = $repository.Tasks.Create($task)
			$repository.Tasks.WaitForCompletion($Task1);

			$packages = $repository.BuiltInPackageRepository.ListPackages("Serilog.Sinks.TextWriter")
			$packages.TotalResults | should be 1
			$packages.Items[0].Version | should be "2.1.0"
		}
	}
	#>

	Context 'C:\Import' {
		it 'should have provided a migration scripts for the Server' {
			$environments = $repository.Environments.FindAll()
			$environments.Count | should be 1
			$environments[0].Name | should be "Development"
		}
	}
	
	Context 'C:\TaskLogs' {
		it 'should contain logs of tasks' {
			$description = "Health check started for Docker Testing";
			$Task = $repository.Tasks.ExecuteHealthCheck($description)
			$repository.Tasks.WaitForCompletion($Task);

			Sleep -Seconds 1
			$files=(Get-ChildItem "./Temp/TaskLogs/$($task.Id.ToLower())_*" -Recurse)
			$files[0].FullName | Should Contain $description
		}
	}

	Context 'C:\MasterKey' {
		it 'should contain a master key file' {
			Test-Path  "./Temp/MasterKey/OctopusServer" | should be $true
			Get-Content  "./Temp/MasterKey/OctopusServer" | Should not Be $null
		}
	}
}
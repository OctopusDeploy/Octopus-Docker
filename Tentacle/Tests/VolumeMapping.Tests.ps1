param(
    [ValidateNotNullOrEmpty()]
	[string]$IPAddress,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusUsername,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusPassword,
	[ValidateNotNullOrEmpty()]
	[string]$OctopusVersion
)
$OctopusURI="http://$($IPAddress):81"

 
Describe 'Volume Mounts' {

	$endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
	$repository = new-object Octopus.Client.OctopusRepository $endpoint
		
	$LoginObj = New-Object Octopus.Client.Model.LoginCommand 
	$LoginObj.Username = $OctopusUsername
	$LoginObj.Password = $OctopusPassword
	$repository.Users.SignIn($LoginObj)
	
	Context 'C:\TentacleHome' {
		it 'should contain logs' {
			Test-Path "../tests/PollingHome/Logs/OctopusTentacle.txt" | should be $true
			Test-Path "../tests/ListeningHome/Logs/OctopusTentacle.txt" | should be $true
		}
	}

	Context 'C:\Applications' {

		function Clean {
			$project = $repository.Projects.FindByName("MyFirstProject")
			if($project -ne $null) {
				$repository.Projects.Delete($project)
			}

			Remove-Item ..\tests\PollingApplications\* -Recurse -Force
			Remove-Item ..\tests\ListeningApplications\* -Recurse -Force
		}

		BeforeEach {
			Clean
		}
	
		AfterEach {
			Clean
		}

		it 'should contain deployed packages' {
			# Create Project
			$pg = $repository.ProjectGroups.FindAll()[0]
			$lc = $repository.Lifecycles.FindAll()[0]
			$env = $repository.Environments.FindAll()[0]
			$project = $repository.Projects.CreateOrModify("MyFirstProject", $pg, $lc)			
			$pkg = New-Object Octopus.Client.Model.PackageResource
			$pkg.PackageId = "Serilog.Sinks.TextWriter"
			$pkg.FeedId ="feeds-builtin"
			$project.DeploymentProcess.AddOrUpdateStep("Deploy").TargetingRoles("app-server", "web-server").AddOrUpdatePackageAction("DeploySeriLog", $pkg)
			$p = $project.Save()

			# Create Release
			$release = new-object Octopus.Client.Model.ReleaseResource
			$release.Version = "1.0.1"
			$release.ProjectId = $p.Instance.Id
				$selectedPackage = New-Object Octopus.Client.Model.SelectedPackage
				$selectedPackage.ActionName = "DeploySeriLog"
				$selectedPackage.StepName = "DeploySeriLog"
				$selectedPackage.Version = "2.1.0"
			$release.SelectedPackages.Add($selectedPackage)
			$release = $repository.Releases.Create($release,  $true)


			# Create Deployment
			$deployment = New-Object Octopus.Client.Model.DeploymentResource
			$deployment.ReleaseId = $release.Id
			$deployment.ProjectId = $release.ProjectId
			$deployment.EnvironmentId = $env.Id
			$deployment = $repository.Deployments.Create($deployment)


			# Wait For Deployment
			$task = $repository.Tasks.Get($deployment.TaskId)
			$repository.Tasks.WaitForCompletion($task, 4, 3);

			Test-Path "../tests/PollingApplications/$($env.Name)/$($pkg.PackageId)" | should be $true
			Test-Path "../tests/ListeningApplications/$($env.Name)/$($pkg.PackageId)" | should be $true
		}
	}
}
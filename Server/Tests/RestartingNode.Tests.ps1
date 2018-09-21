param(
    [ValidateNotNullOrEmpty()]
	[string]$IPAddress,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusUsername,
    [ValidateNotNullOrEmpty()]
	[string]$OctopusPassword,
	[ValidateNotNullOrEmpty()]
    [string]$OctopusVersion,
    [ValidateNotNullOrEmpty()]
    [string]$OSVersion,
    [ValidateNotNullOrEmpty()]
	[string]$ProjectName
)
$DBPassword="N0tS3cr3t!"
$OctopusServerContainer=$ProjectName+"_octopus_1";
$ImageVersion = $(Get-ImageVersion $OctopusVersion $OSVersion);
$MasterKey=$(Get-Content .\Temp\MasterKey\OctopusServer)

function Get-Repository() {
    $IPAddress=$(Get-IPAddress)
    $OctopusURI="http://$($IPAddress):81"
    $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusURI
    $repository = new-object Octopus.Client.OctopusRepository $endpoint
    $LoginObj = New-Object Octopus.Client.Model.LoginCommand 
    $LoginObj.Username = $OctopusUsername
    $LoginObj.Password = $OctopusPassword
    $repository.Users.SignIn($LoginObj)
    return $repository
}

Describe 'Restarting Nodes' {
	Context 'starting new node with no node name' {
        
        Write-Host "Removing old node"
        docker stop $OctopusServerContainer
        docker rm $OctopusServerContainer

        Write-Host "Starting new node"
        docker run --name $OctopusServerContainer -d --interactive --publish 81:81 `
            --env MasterKey=$MasterKey `
            --env sqlDbConnectionString="Server=db,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=$DBPassword;MultipleActiveResultSets=False;Connection Timeout=30;" `
            -v $PSScriptRoot"\..\..\Temp\TaskLogs:C:/TaskLogs" `
            -v $PSScriptRoot"\..\..\Testing\Repository:C:/Repository" `
            octopusdeploy/octopusdeploy-prerelease:$ImageVersion
        Wait-ForServiceToPassHealthCheck $OctopusServerContainer

		it 'should still have the same data as previous node' {
            $repository = Get-Repository 
            $environments = $repository.Environments.FindAll()
			$environments.Count | should be 1
            $environments[0].Name | should be "Development"
        }
        
        it 'should still only indicate that the one default node is present' {
            $repository = Get-Repository 
            $serverNodes = $repository.OctopusServerNodes.FindAll();
            $serverNodes.Count | should be 1
            $serverNodes[0].Name | should be "OctopusNode1"
        }
    }

    Context 'starting secondary node with explicit node name' {
        
        $OctopusServerContainer2=$ProjectName+"_octopus_2";
        Write-Host "Starting secondary new node"
        docker run --name $OctopusServerContainer2 -d --interactive `
        --env ServerNodeName="OctopusNode2" `
        --env MasterKey=$MasterKey `
        --env sqlDbConnectionString="Server=db,1433;Initial Catalog=Octopus;Persist Security Info=False;User ID=sa;Password=$DBPassword;MultipleActiveResultSets=False;Connection Timeout=30;" `
        -v $PSScriptRoot"\..\..\Temp\TaskLogs:C:/TaskLogs" `
        -v $PSScriptRoot"\..\..\Testing\Repository:C:/Repository" `
        octopusdeploy/octopusdeploy-prerelease:$ImageVersion
        Wait-ForServiceToPassHealthCheck $OctopusServerContainer2
        
        it 'should indicate that two nodes are now available' {
            $repository = Get-Repository    
            $serverNodes = $repository.OctopusServerNodes.FindAll();
            $serverNodes.Count | should be 2
        }

        & docker rm -f $ProjectName"_octopus_2"
    }
}
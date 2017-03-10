Configuration ConfigureOctopusTentacle
{
    param ($ApiKey, $OctopusServerUrl, $Environments, $Roles, $ListenPort)

    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present"
            State = "Stopped"
			RegisterWithServer = $True
			
            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "Tentacle"


            # Registration - all parameters required
            ApiKey = $ApiKey
            OctopusServerUrl = $OctopusServerUrl
            Environments = $Environments
			Roles = $Roles
			
			tentacleDownloadUrl ="https://octopus-testing.s3.amazonaws.com/server/Octopus.3.11.2-x64.msi"
            

            # Optional settings
            ListenPort = $ListenPort
            #DefaultApplicationDirectory = "C:\Applications"
            #TentacleHomeDirectory = "C:\Octopus"
        }
    }
}
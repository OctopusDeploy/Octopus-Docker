Configuration InstallOctopusTentacle
{
    param ()

    Import-DscResource -Module OctopusDSC

    Node "localhost"
    {
        cTentacleAgent OctopusTentacle
        {
            Ensure = "Present"
            State = "Stopped"
			RegisterWithServer = $False
			
            # Tentacle instance name. Leave it as 'Tentacle' unless you have more
            # than one instance
            Name = "Tentacle"

            # Registration - all parameters required
			ApiKey = "XX"
            OctopusServerUrl = "http://www.example.com"            
        }
    }
}
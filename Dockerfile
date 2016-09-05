FROM microsoft/windowsservercore:latest

HEALTHCHECK CMD powershell -command "try { $statusCode = (Invoke-WebRequest http://localhost:81 | % {$_.StatusCode}); if ($statusCode -eq 200) { exit 0 }; exit 1 } catch { exit 2 }"

ADD install-octopusdeploy.ps1 /
ADD configure-octopusdeploy.ps1 /
ADD run-octopusdeploy.ps1 /

ENV OctopusAdminUsername admin
ENV OctopusAdminPassword Passw0rd123
ARG OctopusVersion
ENV OctopusVersion ${OctopusVersion}

RUN powershell -File /install-octopusdeploy.ps1

ENTRYPOINT powershell -File /configure-octopusdeploy.ps1 && powershell -File /run-octopusdeploy.ps1

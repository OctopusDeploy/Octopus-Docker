FROM microsoft/windowsservercore:latest

HEALTHCHECK CMD powershell -file /healthcheck.ps1

ADD install-octopusdeploy.ps1 /
ADD configure-octopusdeploy.ps1 /
ADD run-octopusdeploy.ps1 /
ADD healthcheck.ps1 /

ENV OctopusAdminUsername admin
ENV OctopusAdminPassword Passw0rd123
ARG OctopusVersion
ENV OctopusVersion ${OctopusVersion}

RUN powershell -File /install-octopusdeploy.ps1

ENTRYPOINT powershell -File /configure-octopusdeploy.ps1 && powershell -File /run-octopusdeploy.ps1

FROM microsoft/windowsservercore:latest

HEALTHCHECK CMD powershell -file /healthcheck.ps1

ADD scripts/install-octopusdeploy.ps1 /
ADD scripts/configure-octopusdeploy.ps1 /
ADD scripts/run-octopusdeploy.ps1 /
ADD scripts/healthcheck.ps1 /

ADD Source /source

ENV OctopusAdminUsername admin
ENV OctopusAdminPassword Passw0rd123
ARG OctopusVersion
ENV OctopusVersion ${OctopusVersion}

VOLUME ["c:/Octopus"]

RUN powershell -File /install-octopusdeploy.ps1

ENTRYPOINT powershell -File /configure-octopusdeploy.ps1 && powershell -File /run-octopusdeploy.ps1

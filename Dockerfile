FROM microsoft/windowsservercore:latest

HEALTHCHECK --interval=30s --timeout=30s --retries=6 CMD powershell -file /healthcheck.ps1

ADD scripts/*.ps1 /

ENV OctopusAdminUsername admin
ENV OctopusAdminPassword Passw0rd123
ARG OctopusVersion
ENV OctopusVersion ${OctopusVersion}

EXPOSE 81
EXPOSE 10943

VOLUME ["c:/Octopus"]

RUN powershell -File /install-octopusdeploy.ps1  -Verbose

ENTRYPOINT powershell -File /configure-octopusdeploy.ps1 -Verbose && powershell -File /run-octopusdeploy.ps1 -Verbose
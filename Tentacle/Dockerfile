FROM microsoft/windowsservercore:latest

#HEALTHCHECK --interval=30s --timeout=30s --retries=6 CMD powershell -file /healthcheck.ps1

ADD Scripts/*.ps1 /

ARG OctopusVersion
ENV OctopusVersion ${OctopusVersion}

EXPOSE 10933

VOLUME ["c:/Octopus"]

RUN powershell -File /install-octopusdeploy-tentacle.ps1 -Verbose
#ENTRYPOINT powershell -File /configure-octopusdeploy-tentacle.ps1 -Verbose && powershell -File /run-octopusdeploy-tentacle.ps1 -Verbose
#ENTRYPOINT powershell -File /configure-octopusdeploy.ps1 -Verbose && powershell -File /run-octopusdeploy.ps1 -Verbose
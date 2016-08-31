FROM microsoft/windowsservercore:latest

ADD install-octopusdeploy.ps1 /
ADD configure-octopusdeploy.ps1 /

ARG OctopusVersion=3.4.1
ENV OctopusVersion ${OctopusVersion}
ENV OctopusAdminUsername=admin
ENV OctopusAdminPassword=Passw0rd123

RUN powershell -File /install-octopusdeploy.ps1

ENTRYPOINT powershell -File /configure-octopusdeploy.ps1

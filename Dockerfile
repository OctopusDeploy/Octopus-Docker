FROM microsoft/windowsservercore:latest

ADD install-octopusdeploy.ps1 /
ADD run-octopusdeploy.ps1 /
ADD source/ /source

ENV OctopusVersion=3.4.1
ARG SqlServer
ENV OctopusAdminUsername=admin
ENV OctopusAdminPassword=Passw0rd123

RUN powershell -File /install-octopusdeploy.ps1

ENTRYPOINT powershell -File /run-octopusdeploy.ps1

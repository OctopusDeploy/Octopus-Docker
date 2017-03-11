FROM microsoft/windowsservercore:latest

HEALTHCHECK --interval=30s --timeout=30s --retries=6 CMD powershell -file /healthcheck.ps1

EXPOSE 10933

VOLUME ["C:/Applications", "C:/TentacleHome"]

ADD Scripts/*.ps1 /
ADD Installers/ /Installers

ARG OctopusVersion
ENV OctopusVersion ${OctopusVersion}

LABEL 	org.label-schema.schema-version="1.0" \
		org.label-schema.name="Octopus Deploy Tentacle" \
		org.label-schema.vendor="Octopus Deploy" \
		org.label-schema.url="https://octopus.com" \
		org.label-schema.vcs-url="https://github.com/OctopusDeploy/Octopus-Docker" \
		org.label-schema.license="Apache"  \
		org.label-schema.description="Octopus Tentacle instance with auto-registration to Octopus Server" \    
		org.label-schema.build-date=$BUILD_DATE 
	  
RUN powershell -File /install-octopusdeploy-tentacle.ps1 -Verbose

#ENTRYPOINT ["/bin/bash"]
#CMD ["-l"]

ENTRYPOINT powershell -File /configure-octopusdeploy-tentacle.ps1 -Verbose && powershell -File /run-octopusdeploy-tentacle.ps1 -Verbose
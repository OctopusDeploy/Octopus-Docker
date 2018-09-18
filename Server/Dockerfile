FROM microsoft/windowsservercore:latest

HEALTHCHECK --interval=20s --timeout=20s --retries=6 CMD powershell -file ./Server/healthcheck-server.ps1

EXPOSE 81
EXPOSE 10943

ADD Scripts/*.ps1 /Scripts/
ADD Server/Scripts/*.ps1 /Scripts/Server/

#ADD source/ /Installers

ARG OctopusVersion
ENV OctopusVersion ${OctopusVersion}

LABEL   org.label-schema.schema-version="1.0" \
    org.label-schema.name="Octopus Deploy Server" \
    org.label-schema.vendor="Octopus Deploy" \
    org.label-schema.url="https://octopus.com" \
    org.label-schema.vcs-url="https://github.com/OctopusDeploy/Octopus-Docker" \
    org.label-schema.license="Apache"  \
    org.label-schema.description="Octopus Deploy Server Instance" \
    org.label-schema.build-date=$BUILD_DATE

WORKDIR /Scripts
RUN powershell ./Server/build.ps1 -Verbose
#ENTRYPOINT powershell -File ./Server/configure-server.ps1 -Verbose && powershell -File ./Server/run-server.ps1 -Verbose
ENTRYPOINT powershell -File ./Server/run.ps1 -Verbose
ARG SERVERCORE_VERSION=1709
ARG BASE_IMAGE=microsoft/windowsservercore
FROM ${BASE_IMAGE}:${SERVERCORE_VERSION}

HEALTHCHECK --interval=20s --timeout=20s --retries=6 CMD powershell -file ./Server/healthcheck-server.ps1

EXPOSE 81
EXPOSE 10943

ADD Scripts/*.* /Scripts/
ADD Server/Scripts/*.* /Scripts/Server/
#ADD source/ /Installers

ARG OctopusVersion
ENV OctopusVersion ${OctopusVersion}
ENV ServerNodeName "OctopusNode1"

LABEL   org.label-schema.schema-version="1.0" \
    org.label-schema.name="Octopus Deploy Server" \
    org.label-schema.vendor="Octopus Deploy" \
    org.label-schema.url="https://octopus.com" \
    org.label-schema.vcs-url="https://github.com/OctopusDeploy/Octopus-Docker" \
    org.label-schema.license="Apache"  \
    org.label-schema.description="Octopus Deploy Server Instance" \
    org.label-schema.build-date=$BUILD_DATE

WORKDIR /Scripts

#SHELL ["powershell", "-File"]
RUN powershell -File ./Server/build.ps1
ENTRYPOINT ["/Scripts/Server/entrypoint.bat"]

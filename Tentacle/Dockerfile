FROM microsoft/windowsservercore:latest

HEALTHCHECK --interval=20s --timeout=20s --retries=6 CMD powershell -file ./Tentacle/healthcheck-tentacle.ps1

EXPOSE 10933

VOLUME ["C:/Applications", "C:/TentacleHome"]

ADD Scripts/*.ps1 /
ADD Tentacle/Scripts/*.ps1 /Tentacle/
ADD source/ /Installers

ARG TentacleVersion
ENV TentacleVersion ${TentacleVersion}

LABEL   org.label-schema.schema-version="1.0" \
    org.label-schema.name="Octopus Deploy Tentacle" \
    org.label-schema.vendor="Octopus Deploy" \
    org.label-schema.url="https://octopus.com" \
    org.label-schema.vcs-url="https://github.com/OctopusDeploy/Octopus-Docker" \
    org.label-schema.license="Apache"  \
    org.label-schema.description="Octopus Tentacle instance with auto-registration to Octopus Server" \
    org.label-schema.build-date=$BUILD_DATE

RUN powershell -File ./install-base.ps1 -Msi "Octopus.Tentacle" -Verbose && powershell -File ./Tentacle/install-tentacle.ps1 -Verbose
ENTRYPOINT powershell -File ./Tentacle/configure-tentacle.ps1 -Verbose  && powershell -File ./Tentacle/run-tentacle.ps1 -Verbose

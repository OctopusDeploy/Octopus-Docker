FROM microsoft/mssql-server-windows-express:1709

HEALTHCHECK --interval=20s --timeout=20s --retries=6 CMD powershell -file ./Server/healthcheck-server.ps1

EXPOSE 81
EXPOSE 10943
#EXPOSE 1433

ADD Scripts/*.* /Scripts/
ADD Server/Scripts/*.* /Scripts/Server/
ADD Combined/Scripts/*.* /Scripts/Combined/
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
RUN powershell -File ./Combined/build.ps1

CMD ["/Scripts/Combined/entrypoint.bat"]

@echo off

echo "Start Octopus Deploy instance ..."
echo "Run started." > "c:\octopus-run.initstate"
"C:\Program Files\Octopus Deploy\Octopus\Octopus.Server.exe" run --instance OctopusServer --noninteractive
#Requires -RunAsAdministrator

Stop-Service Docker
sc.exe delete Docker
Remove-Item "$env:ProgramFiles\Docker" -Force -Recurse
Remove-Item "$env:ProgramFiles\Linux Containers" -Force -Recurse
Remove-LocalGroup -Name Docker
Get-HNSNetwork | Remove-HNSNetwork
Invoke-WebRequest -UseBasicParsing -OutFile docker-ci-zap.exe "https://github.com/jhowardmsft/docker-ci-zap/blob/master/docker-ci-zap.exe?raw=true"
.\docker-ci-zap.exe -folder "C:\ProgramData\docker"
Remove-Item "$env:ProgramData\Docker" -Recurse



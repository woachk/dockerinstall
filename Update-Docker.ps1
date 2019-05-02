#Requires -RunAsAdministrator

# Take care of already installed bits
# SilentlyContinue is used to not have warnings appear when going through the checks, on a system where Docker is not installed.

if (Get-Service Docker -ErrorAction SilentlyContinue) {
    Stop-Service Docker
    sc.exe delete Docker
    Remove-Item "$env:ProgramFiles\Docker" -Force -Recurse
}
else {
    if (Get-LocalGroup Docker -ErrorAction SilentlyContinue) {

    }
    # Docker group handling
    else {
        New-LocalGroup Docker -Description "Docker Users"
        # Add current user to Docker group by default
        Add-LocalGroupMember -Group Docker -Member $env:UserName
    }
}

# If the previous install didn't succeed, the service might not have been created. As such, SilentlyContinue is used here.
New-Item -ItemType Directory "$env:ProgramFiles\Docker" -ErrorAction SilentlyContinue

Set-Location "$env:ProgramFiles\Docker"
Invoke-WebRequest -UseBasicParsing -OutFile dockerd.exe https://master.dockerproject.org/windows/x86_64/dockerd.exe
Invoke-WebRequest -UseBasicParsing -OutFile docker.exe https://master.dockerproject.org/windows/x86_64/docker.exe

# This is a hack for downloading the proper LCOW version
# You can't just use "latest" here because of LCOW kernels being flagged as pre-release

$latestRelease = Invoke-WebRequest -UseBasicParsing https://api.github.com/repos/linuxkit/lcow/releases
$json = $latestRelease.Content | ConvertFrom-Json
$latestVersion = $json[0].tag_name
$url = "https://github.com/linuxkit/lcow/releases/download/$latestVersion/release.zip"

# Second part of LCOW setup
# See https://github.com/linuxkit/lcow/blob/master/README.md

Invoke-WebRequest -UseBasicParsing -OutFile release.zip $url
Remove-Item "$env:ProgramFiles\Linux Containers" -Force -Recurse
Expand-Archive release.zip -DestinationPath "$Env:ProgramFiles\Linux Containers\."
Remove-Item release.zip

# Service handling
.\dockerd.exe --register-service

# Windows 10 version 1809 or later
if ([System.Environment]::OSVersion.Version.Build -ge 17763) {
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Docker" -Name ImagePath -Value "$env:ProgramFiles\Docker\dockerd.exe --run-service --experimental --exec-opt isolation=process -G Docker"
}
# On older builds, do not set process isolation by default because disabled by dockerd (you can download an alternate docker daemon without the check, but doing so is outside the scope of this script)
else {
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Docker" -Name ImagePath -Value "$env:ProgramFiles\Docker\dockerd.exe --run-service --experimental -G Docker"
}

# Apply our settings
Stop-Service Docker
Start-Service Docker

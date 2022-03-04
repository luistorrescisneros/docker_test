FROM mcr.microsoft.com/windows/servercore:1809
#FROM mcr.microsoft.com/dotnet/sdk:6.0.200-windowsservercore-ltsc2019

LABEL Description="Windows Server Core development environment for Qbs with Qt, Chocolatey and various dependencies for testing Qbs modules and functionality"

# Disable crash dialog for release-mode runtimes
RUN reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f
RUN reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f

# Install VS from the website since chocolatey has broken .NET 4.8 (dotnetfx package) which is a
# dependency for the visualstudio2019buildtools package
RUN mkdir C:\\TEMP
RUN powershell -NoProfile -ExecutionPolicy Bypass -Command \
    Invoke-WebRequest "https://aka.ms/vs/16/release/vs_community.exe" \
    -OutFile "C:\\TEMP\\vs_community.exe" -UseBasicParsing

RUN "C:\\TEMP\\vs_community.exe"  --quiet --wait --norestart --noUpdateInstaller \
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
    --add Microsoft.VisualStudio.Component.Windows10SDK.18362dir

RUN powershell -NoProfile -ExecutionPolicy Bypass -Command \
    $Env:chocolateyVersion = '0.10.15' ; \
    $Env:chocolateyUseWindowsCompression = 'false' ; \
    "[Net.ServicePointManager]::SecurityProtocol = \"tls12, tls11, tls\"; iex ((New-Object System.Net.WebClient).DownloadString('http://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

ARG QBS_VERSION=1.21.0
RUN choco install -y python && \
    choco install -y 7zip --version 19.0 && \
    choco install -y git --version 2.24.0 --params "/GitAndUnixToolsOnPath" && \
    choco install -y qbs --version %QBS_VERSION% 

# for building the documentation
RUN pip install beautifulsoup4 lxml

# Installing msys2 for mingw64
# Source https://www.msys2.org/docs/ci/
RUN powershell -Command $ErrorActionPreference='Stop'; $ProgressPreference ='SilentlyContinue'; \
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -UseBasicParsing -uri "https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe" -OutFile msys2.exe; \
    .\msys2.exe -y -oC:\; \
    Remove-Item msys2.exe ; \
    function msys() { C:\msys64\usr\bin\bash.exe @('-lc') + @Args; } \
    msys ' '; \
    msys 'pacman --noconfirm -Syuu'; \
    msys 'pacman --noconfirm -Syuu'; \
    msys 'pacman --noconfirm -Scc'; \
    msys 'pacman --noconfirm -S --needed base-devel mingw-w64-x86_64-toolchain' 


########### Install Qt #############
ARG QT_VERSION=5.15.1
COPY scripts/install-qt.sh install-qt.sh

RUN bash -c "./install-qt.sh -d /c/Qt --version ${QT_VERSION} --toolchain win64_mingw81 qtbase qtdeclarative qttools qtscript" 
ENV QTDIR64=C:\\Qt\\${QT_VERSION}\\mingw81_64

#RUN bash -c "./install-qt.sh -d /c/Qt --version ${QT_VERSION} --toolchain win32_mingw81 qtbase qtdeclarative qttools qtscript"
#ENV QTDIR=C:\\Qt\\${QT_VERSION}\\msvc2019
#win32_msvc2019

RUN qbs setup-toolchains --detect && \
    qbs setup-qt %QTDIR64%\\bin\\qmake.exe qt64 && \
    qbs config defaultProfile qt64  
#    qbs setup-qt %QTDIR%\\bin\\qmake.exe qt && \

# Including qmake into PATH
# SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

# Installing conan
# https://docs.conan.io/en/latest/installation.html
RUN pip install conan

# Defining a PATH is taken from https://github.com/dotnet/dotnet-docker/blob/20ea9f045a8eacef3fc33d41d58151d793f0cf36/2.1/sdk/nanoserver-1909/amd64/Dockerfile#L28-L29
# Including qmake64 and mingw64 into PATH
SHELL ["cmd", "/S", "/C"]
USER ContainerAdministrator
RUN setx /M PATH "%PATH%;%QTDIR64%\bin"
RUN setx /M PATH "%PATH%;C:\msys64\mingw64\bin"
#USER ContainerUser

#ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]


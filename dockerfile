FROM mcr.microsoft.com/windows/servercore:ltsc2016

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install .NET 4.8
RUN Invoke-WebRequest -Uri "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe" -OutFile dotnet-framework-installer.exe
RUN .\dotnet-framework-installer.exe /q

ENV NUGET_VERSION 4.4.1
RUN New-Item -Type Directory $Env:ProgramFiles\NuGet;
RUN Invoke-WebRequest -UseBasicParsing https://dist.nuget.org/win-x86-commandline/v$Env:NUGET_VERSION/nuget.exe -OutFile $Env:ProgramFiles\NuGet\nuget.exe

# Install VS Test Agent
RUN Invoke-WebRequest -UseBasicParsing https://download.visualstudio.microsoft.com/download/pr/4eef3cca-9da8-417a-889f-53212671e83b/50a7f7a24b21910a7cbe093fa150fd31/vs_testagent.exe -OutFile vs_TestAgent.exe;
RUN Start-Process vs_TestAgent.exe -ArgumentList '--quiet', '--norestart', '--nocache' -NoNewWindow -Wait;

# Install VS Build Tools
RUN Invoke-WebRequest -UseBasicParsing https://download.visualstudio.microsoft.com/download/pr/4da568ff-b8aa-43ab-92ec-a8129370b49a/6fb89b999fed6f395622e004bfe442eb/vs_buildtools.exe -OutFile vs_BuildTools.exe;
RUN setx /M DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1;
RUN Start-Process vs_BuildTools.exe -ArgumentList '--add', 'Microsoft.VisualStudio.Workload.MSBuildTools', '--add', 'Microsoft.VisualStudio.Workload.NetCoreBuildTools', '--add', 'Microsoft.Component.ClickOnce.MSBuild', '--quiet', '--norestart', '--nocache' -NoNewWindow -Wait;

# Install .NET 4.8 SDK
RUN Invoke-WebRequest -UseBasicParsing https://dotnetbinaries.blob.core.windows.net/dockerassets/sdk_tools48.zip -OutFile sdk_tools48.zip;
RUN Expand-Archive sdk_tools48.zip;
RUN Start-Process msiexec -ArgumentList '/i', 'sdk_tools48\sdk_tools48.msi', '/quiet', 'VSEXTUI=1' -NoNewWindow -Wait;

# Install web targets
RUN Invoke-WebRequest -UseBasicParsing https://dotnetbinaries.blob.core.windows.net/dockerassets/MSBuild.Microsoft.VisualStudio.Web.targets.2019.05.zip -OutFile MSBuild.Microsoft.VisualStudio.Web.targets.zip;
RUN Expand-Archive MSBuild.Microsoft.VisualStudio.Web.targets.zip -DestinationPath \"${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Microsoft\VisualStudio\v16.0\";

ENV ROSLYN_COMPILER_LOCATION "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn"

# Set PATH in one layer to keep image size down.
RUN setx /M PATH $(${Env:PATH} + \";${Env:ProgramFiles}\NuGet\" + \";${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\" + \";${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\" + \";${Env:ProgramFiles(x86)}\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\" + \";${Env:ProgramFiles(x86)}\Microsoft SDKs\ClickOnce\SignTool\")

# Install Targeting Packs
RUN @('4.0', '4.5.2', '4.6.2', '4.7.2', '4.8') | %{ Invoke-WebRequest -UseBasicParsing https://dotnetbinaries.blob.core.windows.net/referenceassemblies/v${_}.zip -OutFile referenceassemblies.zip; Expand-Archive referenceassemblies.zip -DestinationPath \"${Env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\"; Remove-Item -Force referenceassemblies.zip; }

# Install git
# RUN Invoke-WebRequest -UseBasicParsing 'https://github.com/git-for-windows/git/releases/download/v2.12.2.windows.2/MinGit-2.12.2.2-64-bit.zip' -OutFile MinGit.zip;
COPY MinGit.zip .
RUN Expand-Archive c:\MinGit.zip -DestinationPath c:\MinGit;
RUN setx /M PATH $(${Env:PATH} + \";C:\MinGit\cmd\");
RUN Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\' -Name Path -Value $env:PATH

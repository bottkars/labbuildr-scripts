<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>
#requires -version 3
[CmdletBinding()]
param(
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    [ValidateSet(
    '1.12.0'
    )]
    $Docker_VER='1.12.0'
    )
$Nodescriptdir = "$Scriptdir\Node"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
if (!(Test-Path $logpath))
    {
    New-Item -ItemType Directory -Path $logpath -Force
    }
$Logfile = New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log"
Set-Content -Path $Logfile $MyInvocation.BoundParameters
############
.$Nodescriptdir\test-sharedfolders.ps1 -Folder $Sourcepath

$Docker_Downloadfile = "docker-$($Docker_VER).zip"
$Docker_Uri = "https://get.docker.com/builds/Windows/x86_64/"
$Uri = Join-Path $Docker_Uri $Docker_Downloadfile

Invoke-WebRequest $Uri -OutFile "$env:TEMP\$Docker_Downloadfile" -UseBasicParsing
Expand-Archive -Path "$env:TEMP\$Docker_Downloadfile" -DestinationPath $env:ProgramFiles
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Docker", [EnvironmentVariableTarget]::Machine)
$env:Path = $env:Path + ";C:\Program Files\Docker"
& $env:ProgramFiles\docker\dockerd.exe --register-service
Start-Service Docker
Install-PackageProvider ContainerImage -Force
Install-ContainerImage -Name WindowsServerCore
Restart-Service docker
docker tag windowsservercore:10.0.14300.1030 windowsservercore:latest

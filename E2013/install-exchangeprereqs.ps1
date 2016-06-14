<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
[CmdletBinding()]
param(
$ex_version= "E2013",
$Prereq ="Prereq",
$Scriptdir = '\\vmware-host\Shared Folders\Scripts',
$SourcePath = '\\vmware-host\Shared Folders\Sources',
$logpath = "c:\Scripts"
)
$Nodescriptdir = Join-Path $Scriptdir "Node"
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
$Prereq_dir = Join-Path $SourcePath $Prereq
.$Nodescriptdir\test-sharedfolders.ps1 -folder $Sourcepath

$Setupcmd = "UcmaRuntimeSetup.exe"
$Setuppath = "$Prereq_dir\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
$argumentList = "/passive /norestart"
Start-Process -FilePath $Setuppath -ArgumentList $argumentList -Wait -NoNewWindow

$Setupcmd = "FilterPack64bit.exe"
$Setuppath = "$Prereq_dir\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
$argumentList = "/passive /norestart"
Start-Process -FilePath $Setuppath -ArgumentList $argumentList -Wait -NoNewWindow

$Setupcmd = "filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe"
$Setuppath = "$Prereq_dir\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
$argumentList = "/passive /norestart"
Start-Process -FilePath $Setuppath -ArgumentList $argumentList -Wait -NoNewWindow

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

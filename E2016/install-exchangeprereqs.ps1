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
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$logpath = "c:\Scripts",
$ex_version= "E2016",
$Prereq ="Prereq" 
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
.$Nodescriptdir\test-sharedfolders.ps1

$Setupcmd = "UcmaRuntimeSetup.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Nodescriptdir\test-setup -setup $Setupcmd -setuppath $Setuppath
Start-Process $Setuppath -ArgumentList "/q /norestart" -Wait

$Setupcmd = "NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Nodescriptdir\test-setup -setup $Setupcmd -setuppath $Setuppath
Start-Process $Setuppath -ArgumentList "/q /norestart"
<#
$Setupcmd = "FilterPack64bit.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Nodescriptdir\test-setup -setup $Setupcmd -setuppath $Setuppath
.$Setuppath /passive /norestart

$Setupcmd = "filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe"
$Setuppath = "$SourcePath\$ex_version$Prereq\$Setupcmd"
.$Nodescriptdir\test-setup -setup $Setupcmd -setuppath $Setuppath
.$Setuppath /passive /norestart
#>
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

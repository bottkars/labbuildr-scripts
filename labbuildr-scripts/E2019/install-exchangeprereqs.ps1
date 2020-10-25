﻿<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr builds your on-demand labs
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>
#requires -version 3
[CmdletBinding()]
param(
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$logpath = "c:\Scripts",
$ex_version= "E2019",
$Prereq ="Prereqs",
$NET_VER = "48",
$KB

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
$Prereq_dir = Join-Path $SourcePath $Prereq
.$Nodescriptdir\test-sharedfolders.ps1 -folder $SourcePath

.$Nodescriptdir\install-netframework.ps1 -Net_Ver $NET_VER -Prereq $Prereq -scriptdir $Scriptdir -Sourcepath $SourcePath
if ($KB)
	{
	.$Nodescriptdir\install-KB.ps1 -KB $KB -KBFolder WindowsUpdate -Sourcepath $SourcePath
	}
$Setupcmd = "UcmaRuntimeSetup.exe"
$Setuppath = "$Prereq_dir\$Setupcmd"
.$Nodescriptdir\test-setup -setup $Setupcmd -setuppath $Setuppath
$argumentList = "/passive /norestart"
Start-Process -FilePath $Setuppath -ArgumentList $argumentList -Wait -NoNewWindow

$Setupcmd = "vcredist11.exe"
$Setuppath = "$Prereq_dir\$Setupcmd"
.$Nodescriptdir\test-setup -setup $Setupcmd -setuppath $Setuppath
$argumentList = "/passive /norestart"
Start-Process -FilePath $Setuppath -ArgumentList $argumentList -Wait -NoNewWindow

$Setupcmd = "vcredist12.exe"
$Setuppath = "$Prereq_dir\$Setupcmd"
.$Nodescriptdir\test-setup -setup $Setupcmd -setuppath $Setuppath
$argumentList = "/passive /norestart"
Start-Process -FilePath $Setuppath -ArgumentList $argumentList -Wait -NoNewWindow

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

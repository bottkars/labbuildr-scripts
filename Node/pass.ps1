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
$pass,
[switch]$reboot,
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$logpath = "c:\Scripts"
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

New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "Pass$Pass" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\$Pass.pass`""
if ($reboot.IsPresent){restart-computer -force}

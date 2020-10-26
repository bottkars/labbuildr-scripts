<#
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
    $Password = "Password123!",
    $ex_version= "E2013",
    $BackupUser = "DPSBackupUser",
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

############
$Domain = $env:USERDOMAIN
Copy-Item -Path 'C:\scripts\Networker User for Microsoft.lnk' C:\Users\Public\Desktop
# Copy-Item -Path 'C:\scripts\ecp.website' C:\Users\Public\Desktop
."$Nodescriptdir\set-autologon.ps1" -domain $Domain -user $BackupUser -Password $password


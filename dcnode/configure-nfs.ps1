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
param (
$logpath = "c:\Scripts"
)
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
$Dirname = "nfs"
$Sharename = $env:USERDOMAIN+$dirname
$nfsdir = join-path $env:SystemDrive $Dirname
Add-WindowsFeature fs-nfs-service -IncludeManagementTools
New-Item -ItemType directory c:\nfs
New-NfsShare -Name $sharename -Path $nfsdir  -Permission readwrite  -Authentication sys -unmapped $true -AllowRootAccess $true

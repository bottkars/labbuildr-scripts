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
$sp_version= "SP2013sp1fndtn",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$Setupcmd = "Setup.exe",
[Validateset('AAG','MSDE')]$DBtype,
$DBInstance
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
.$Builddir\test-sharedfolders.ps1
$Setuppath = "$SourcePath\$sp_version\$Setupcmd"
$Nodescriptdir = Join-Path $Scriptdir "Node"
.$NodeScriptDir\test-setup.ps1 -setup "Sharepoint 2013" -setuppath $Setuppath
switch ($DBtype)
    {
    'AAG'
    {
    $arguments = "/config `"$Sourcepath\$sp_version\files\setupfarmsilent\config.xml`""
    }
    'MSDE'
    {
    }
    default
    {
    $arguments = "/config `"$Sourcepath\$sp_version\files\setupsilent\config.xml`""
    }

    }

Write-Warning "Installing Sharepoint may take up to 25 Minutes"
Start-Process $Setuppath -ArgumentList $arguments -Wait

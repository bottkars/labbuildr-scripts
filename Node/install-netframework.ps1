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
    [Parameter(ParameterSetName = "1", Mandatory = $false)]
    [ValidateSet(
    '451','452','46','461'
    )][string]$Net_Ver="452",
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
switch ($Net_Ver)
    {
        '451'
        {}
        '452'
        {}
        '46'
        {}
        '461'
        {}
    }


.$Nodescriptdir\test-sharedfolders.ps1 -folder $Sourcepath
# NETFX 4.52 Setup
$Setupcmd = "NDP$Net_Ver*.exe"
$Setuppath = "$SourcePath\$Prereq\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
Pause
Start-Process $Setuppath -ArgumentList "/passive /norestart" -PassThru -Wait

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

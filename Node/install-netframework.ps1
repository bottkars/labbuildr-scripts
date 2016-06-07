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
    $logpath = "c:\Scripts",
    $prereq = 'prereq'
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
        {        
        $Setupcmd = "NDP451-KB2858728-x86-x64-AllOS-ENU.exe"
        }
        '452'
        {        
        $Setupcmd = "NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
        }
        '46'
        {        
        $Setupcmd = "NDP46-KB3045557-x86-x64-AllOS-ENU.exe"
        }
        '461'
        {
        $Setupcmd = "NDP461-KB3102436-x86-x64-AllOS-ENU.exe"
        }
    }


.$Nodescriptdir\test-sharedfolders.ps1 -folder $Sourcepath
# NETFX 4.52 Setup
$Setuppath = "$SourcePath\$Prereq\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
Write-Host -ForegroundColor Magenta " ==> installing .Net Framework $Net_Ver"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
Start-Process $Setuppath -ArgumentList "/passive /norestart" -PassThru -Wait

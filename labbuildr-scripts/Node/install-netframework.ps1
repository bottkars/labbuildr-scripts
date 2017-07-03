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
    [Parameter(ParameterSetName = "1", Mandatory = $false)]
    [ValidateSet(
    '451','452','46','461','462'
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
		'462'
		{
		$Setupcmd = "NDP462-KB3151800-x86-x64-AllOS-ENU.exe"
		}
    }


.$Nodescriptdir\test-sharedfolders.ps1 -folder $Sourcepath
# NETFX 4.52 Setup
$Setuppath = "$SourcePath\$prereq\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
Write-Host -ForegroundColor Magenta " ==> installing .Net Framework $Net_Ver from $Setuppath"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
Start-Process $Setuppath -ArgumentList "REBOOT=R /passive /norestart" -PassThru -Wait

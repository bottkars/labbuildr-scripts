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
    [ValidateSet('SC2012_R2','SC2016')]
    $SC_VERSION = "SC2012_R2",
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $Prereq ="Prereq",
    [string]$SysCtr = "sysctr"
)
$Nodescriptdir = "$Scriptdir\NODE"
$EXScriptDir = "$Scriptdir\$ex_version"
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
######################################################################
############ WAIK Setup
switch ($SC_VERSION)
    {
    "SC2012_R2"
        {
        $WAIK = "WAIK_8.1"
        }
    default
        {
        $WAIK = "WAIK_10_1607"
        }
    }
$Setupcmd = "adksetup.exe"
$Setuppath = "$SourcePath\$WAIK\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting ADKSETUP"
Start-Process $Setuppath -ArgumentList "/ceip off /features OptionID.DeploymentTools OptionID.WindowsPreinstallationEnvironment /quiet"
Start-Sleep  -Seconds 30
while (Get-Process | where {$_.ProcessName -eq "adksetup"}){
Start-Sleep -Seconds 5
Write-Host -NoNewline -ForegroundColor Yellow "."
}

$Setupcmd = "sqlncli.msi"
$Setuppath = "$SourcePath\$Prereq\$SC_VERSION\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
$SetupArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $SetupArgs -PassThru -Wait

$Setupcmd = "SqlCmdLnUtils.msi"
$Setuppath = "$SourcePath\$Prereq\$SC_VERSION\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
$SetupArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $SetupArgs -PassThru -Wait

# NETFX 4.52 Setup
$Setupcmd = "NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
$Setuppath = "$SourcePath\$Prereq\$SC_VERSION\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
Start-Process $Setuppath -ArgumentList "/passive /norestart" -PassThru -Wait

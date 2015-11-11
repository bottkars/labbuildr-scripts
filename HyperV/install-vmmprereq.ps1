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
    [ValidateSet('SC2012_R2_SCVMM','SCTP3_SCVMM')]$SCVMM_VER = "SC2012_R2_SCVMM",
    $Prereq ="Prereq"
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
$Setupcmd = "adksetup.exe"
$Setuppath = "$SourcePath\$SCVMM_VER$Prereq\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting ADKSETUP"
Start-Process $Setuppath -ArgumentList "/ceip off /features OptionID.DeploymentTools OptionID.WindowsPreinstallationEnvironment /quiet"
Start-Sleep  -Seconds 30
while (Get-Process | where {$_.ProcessName -eq "adksetup"}){
Start-Sleep -Seconds 5
Write-Host -NoNewline -ForegroundColor Yellow "."
}


$Setupcmd = "sqlncli.msi"
$Setuppath = "$SourcePath\$SCVMM_VER$Prereq\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
$SetupArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $SetupArgs -PassThru -Wait

$Setupcmd = "SqlCmdLnUtils.msi"
$Setuppath = "$SourcePath\$SCVMM_VER$Prereq\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
$SetupArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $SetupArgs -PassThru -Wait

# NETFX 4.52 Setup
$Setupcmd = "NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
$Setuppath = "$SourcePath\$SCVMM_VER$Prereq\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
Start-Process $Setuppath -ArgumentList "/passive /norestart" -Wait

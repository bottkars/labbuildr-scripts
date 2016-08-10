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
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    [ValidateSet(
    '4.0.0.0',
    '3.7.1.0','3.7.0.0',
    '3.6.0.3'
    )]
    $SRM_VER='4.0.0.0'
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
.$Nodescriptdir\test-sharedfolders.ps1 -Folder $Sourcepath
############
$Setuppath = "$SourcePath\ViPRSRM\ViPR_SRM_$($SRM_VER)_Win64.exe"
Write-Warning "Installing SRM $SRM_VER, this could take up to 10 Minutes"
.$Nodescriptdir\test-setup.ps1 -setup SRM -setuppath $Setuppath
Write-Warning "Installing SRM $SRM_VER"

if ($SRM_VER -ge "4.0.0.0")
    {
    $Arguments = "/S /ACCEPTEULA=Yes /INSTALL-Type=Default" 
    }
else
    {
    $Arguments = "/S" 
    }
Start-Process -FilePath $Setuppath -ArgumentList $Arguments -PassThru -Wait
Start-Process "http://$($Env:COMPUTERNAME):58080/APG/"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }


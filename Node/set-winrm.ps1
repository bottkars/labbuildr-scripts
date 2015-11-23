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
#.$Nodescriptdir\test-sharedfolders.ps1
##### Configure WINRM
Enable-PSRemoting -Confirm:$false -Force
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value True
Set-Item -Path WSMan:\localhost\Service\AllowRemoteAccess True
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted True
Set-Item -Path WSMan:\localhost\Service\Auth\Kerberos True
.$Nodescriptdir\Add-DomainUserToLocalGroup.ps1 -computer $env:COMPUTERNAME -group Administrators -domain $env:USERDNSDOMAIN -user SVC_WINRM -ScriptDir $scriptdir
.$Nodescriptdir\Add-DomainUserToLocalGroup.ps1 -computer $env:COMPUTERNAME -group "Remote Desktop Users" -domain $env:USERDNSDOMAIN -user SVC_WINRM -ScriptDir $Scriptdir

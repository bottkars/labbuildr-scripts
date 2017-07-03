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
[Parameter(Mandatory=$false)][string]$domain = $Env:USERDOMAIN,
[Parameter(Mandatory=$true)][string]$user,
[Parameter(Mandatory=$false)][string]$Password = "Password123!"
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

$WinLogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $WinLogonPath -Name "AutoAdminLogon" -Value "1" 
Set-ItemProperty $WinLogonPath -Name "DefaultUsername" -Value "$domain\$User"
Set-ItemProperty $WinLogonPath -Name "DefaultDomainname" -Value "$domain"
Set-ItemProperty $WinLogonPath -Name "DefaultPassword" -Value "$Password"

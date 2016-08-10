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
Set-Service MpsSvc -StartupType Automatic
Start-Service  MpsSvc
Set-NetFirewallProfile -Profile Domain,Private -Enabled False
write-verbose "Configuring UAC"
set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 
set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 00000000 
<#
if ([environment]::OSVersion.Version.Major -ge 10)
    {
    New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "FilterAdministratorToken" -Value 1 -PropertyType DWORD
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\UIPI" -Name "(Default)" -Value 1
    }
#>

Write-Verbose "computer needs to be rebooted to finish UAC"
# Restart-Computer

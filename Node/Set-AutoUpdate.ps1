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
[Validateset('Windows','never','Notify','AutoDownload','AutoInstall')]$UpdateType = "never",
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



$WUPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\"
$AUPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
 
If(Test-Path -Path $WUPath) {
    Remove-Item -Path $WUPath -Recurse
}
 
 
If ($UpdateType -ne 'Windows') {
    New-Item -Path $WUPath
    New-Item -Path $AUPath
}

Write-Host " ==>Setting Windows Update to $UpdateType "

switch ($UpdateType)
	{
		'Windows'
		{
		}
		'never'
		{
		Set-ItemProperty -Path $AUPath -Name NoAutoUpdate -Value 1
		}
		'Notify'
		{
		Set-ItemProperty -Path $AUPath -Name NoAutoUpdate -Value 0
		Set-ItemProperty -Path $AUPath -Name AUOptions -Value 2
		Set-ItemProperty -Path $AUPath -Name ScheduledInstallDay -Value 0
		Set-ItemProperty -Path $AUPath -Name ScheduledInstallTime -Value 3
		}
		'AutoDownload'
		{
		Set-ItemProperty -Path $AUPath -Name NoAutoUpdate -Value 0
		Set-ItemProperty -Path $AUPath -Name AUOptions -Value 3
		Set-ItemProperty -Path $AUPath -Name ScheduledInstallDay -Value 0
		Set-ItemProperty -Path $AUPath -Name ScheduledInstallTime -Value 3
		}
		'AutoInstall'
		{
		Set-ItemProperty -Path $AUPath -Name NoAutoUpdate -Value 0
		Set-ItemProperty -Path $AUPath -Name AUOptions -Value 4
		Set-ItemProperty -Path $AUPath -Name ScheduledInstallDay -Value 0
		Set-ItemProperty -Path $AUPath -Name ScheduledInstallTime -Value 3
		}

	}
 

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

$WSEdition = Get-WindowsEdition -Online
if ($WSEdition.Edition -match "cor")
	{
		$core = $true
	}

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
if (!$core) 
{
Write-Host -ForegroundColor Magenta "Disabling IESEC"
$AdminKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}”
$UserKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}”
Set-ItemProperty -Path $AdminKey -Name “IsInstalled” -Value 0
Set-ItemProperty -Path $UserKey -Name “IsInstalled” -Value 0
#Stop-Process -Name Explorer
Write-Host “IE Enhanced Security Configuration (ESC) has been disabled.” -ForegroundColor Green
}
$vmwarehost = "vmware-host"
Write-Host -ForegroundColor Magenta "Setting $vmwarehost as local intranet"
$Zonemaps = ("HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap")
 Foreach ($Zonemap in $Zonemaps)
    {
    Write-Host "Setting $Zonemap for $Host"
    $Ranges = "$Zonemap\Ranges"
    $Range1 = New-Item -Path $Ranges -Name "Range1" -Force
    Set-ItemProperty $ZoneMap -Name "UNCAsIntranet" -Value "1"
    Set-ItemProperty $ZoneMap -Name "AutoDetect" -Value "1"
    $Range1 | New-ItemProperty -Name ":Range" -Value $vmwarehost
    $Range1 | New-ItemProperty -Name "file" -PropertyType DWORD -Value  "1"
   }
Write-Host -ForegroundColor Gray " ==>setting low risk associations"
$Associations = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments"
if (!(test-path $Associations))
	{
	$Item = New-Item -ItemType Directory $Associations
	}
Set-ItemProperty -Path $Associations -Name "LowRiskFileTypes" -Value ".exe;.bat;.reg;.vbs"

Set-ExecutionPolicy -ExecutionPolicy Bypass -Confirm:$false -Force

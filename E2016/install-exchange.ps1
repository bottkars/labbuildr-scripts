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
[Parameter(Mandatory=$true)]
[ValidateSet('Preview1','final')]$ex_cu,
$ExDatabasesBase = "C:\ExchangeDatabases",
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$logpath = "c:\Scripts",
$ex_version= "E2016",
$Prereq ="Prereq", 
$Setupcmd = "Setup.exe"
)
$Nodescriptdir = "$Scriptdir\NODE"
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

$DB1 = "DB1_"+$env:COMPUTERNAME
$DBpath =  New-Item -ItemType Directory -Path M:\DB1
$LogPath = New-Item -ItemType Directory -Path N:\DB1

.$Nodescriptdir\test-sharedfolders.ps1

$Setuppath = "$SourcePath\$ex_version$ex_cu\$Setupcmd"
.$Nodescriptdir\test-setup -setup Exchange -setuppath $Setuppath


Start-Process $Setuppath -ArgumentList "/mode:Install /role:Mailbox /OrganizationName:`"$Env:USERDOMAIN`" /IAcceptExchangeServerLicenseTerms /MdbName:$DB1 /DbFilePath:$ExDatabasesBase\DB1\DB1.EDB /LogFolderPath:$ExDatabasesBase\DB1\DB1.LOG" -Wait
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
# New-Item -ItemType File -Path "c:\scripts\exchange.pass"
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name $ScriptName -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\exchange.pass`""
Restart-Computer
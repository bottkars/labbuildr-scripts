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
	[Parameter(Mandatory=$true)]
    [ValidateSet('final','cu1','cu2','cu3','cu4','cu5','cu6','cu7')]
	$ex_cu,
	$ExDatabasesBase = "C:\ExchangeDatabases",
	[ValidateSet('iso')]$install_from,
	$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
	$SourcePath = "\\vmware-host\Shared Folders\Sources",
	$logpath = "c:\Scripts",
	$ex_version= "E2019",
	$Prereq ="Prereq" 
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
if (!(Test-Path $logpath))
    {
    New-Item -ItemType Directory -Path $logpath -Force
    }
$Logfile = New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log"
Set-Content -Path $Logfile $MyInvocation.BoundParameters
############
$Setupcmd = "Setup.exe"


$Driveletter = (Get-Volume | where FileSystemLabel -eq "EXCHANGESERVER2019-X64-$($ex_cu)").DriveLetter
#$Driveletter = "E" # (Get-Volume | where { $_.size -eq $ismount.Size}).driveletter
$Setuppath = "$($Driveletter):\$Setupcmd"
$DB1 = "DB1_"+$env:COMPUTERNAME
$ArgumentList = "/mode:Install /role:Mailbox /OrganizationName:`"$Env:USERDOMAIN`" /IAcceptExchangeServerLicenseTerms  /InstallWindowsComponents /MdbName:$DB1 /DbFilePath:$ExDatabasesBase\DB1\DB1.DB\DB1.EDB /LogFolderPath:$ExDatabasesBase\DB1\DB1.LOG"
Start-Process $Setuppath -ArgumentList $ArgumentList -Wait -NoNewWindow
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name $ScriptName -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\exchange.pass`""
Restart-Computer -force

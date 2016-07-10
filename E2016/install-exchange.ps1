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
[ValidateSet('cu2','cu1','final')]
$ex_cu,
$ExDatabasesBase = "C:\ExchangeDatabases",
[ValidateSet('exe','iso')]$install_from,
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$logpath = "c:\Scripts",
$ex_version= "E2016",
$Prereq ="Prereq" 
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
$Exchange_Dir = Join-Path $Sourcepath "Exchange"
.$Nodescriptdir\test-sharedfolders.ps1 -folder $SourcePath
$Setupcmd = "Setup.exe"
if ($install_from -eq "exe")
    {
    $Setuppath = "$Exchange_Dir\$ex_version\$EX_Version$ex_cu\$Setupcmd"
    .$Nodescriptdir\test-setup -setup $Ex_version -setuppath $Setuppath
    }
else
    {
    $Isopath = "$Exchange_Dir\$ex_version\ExchangeServer2016-$ex_cu.iso"
    Write-Verbose $Isopath
    .$Nodescriptdir\test-setup -setup $Ex_version -setuppath $Isopath
    Write-Host -ForegroundColor Gray "Copying Exchange ISO locally"
    Copy-Item $Isopath -Destination "$env:USERPROFILE\Downloads"
    $Temp_Iso = "$env:USERPROFILE\Downloads\ExchangeServer2016-$ex_cu.iso"
    $ismount = Mount-DiskImage -ImagePath $Temp_Iso -PassThru
    $Driveletter = (Get-Volume | where { $_.size -eq $ismount.Size}).driveletter
    $Setuppath = "$($Driveletter):\$Setupcmd"
    }



$DB1 = "DB1_"+$env:COMPUTERNAME
$ArgumentList = "/mode:Install /role:Mailbox /OrganizationName:`"$Env:USERDOMAIN`" /IAcceptExchangeServerLicenseTerms /MdbName:$DB1 /DbFilePath:$ExDatabasesBase\DB1\DB1.DB\DB1.EDB /LogFolderPath:$ExDatabasesBase\DB1\DB1.LOG"
Start-Process $Setuppath -ArgumentList $ArgumentList -Wait -NoNewWindow
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name $ScriptName -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\exchange.pass`""
Restart-Computer

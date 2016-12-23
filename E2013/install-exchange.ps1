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
    [ValidateSet('cu1','cu2','cu3','sp1','cu5','cu6','cu7','cu8','cu9','cu10','cu11','cu12','cu13','cu14','cu15')]
    [alias('ex_cu')]$e15_cu,
    $ExDatabasesBase = "C:\ExchangeDatabases",
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $ex_version= "E2013",
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
$Exchange_Dir = Join-Path $Sourcepath "Exchange"
.$Nodescriptdir\test-sharedfolders.ps1 -folder $Sourcepath
$Setuppath = "$Exchange_Dir\$ex_version\$EX_Version$($e15_cu)\$Setupcmd"
.$Nodescriptdir\test-setup -setup $Ex_version -setuppath $Setuppath

$DB1 = "DB1_"+$env:COMPUTERNAME
$ArgumentLst = "/mode:Install /role:ClientAccess,Mailbox /OrganizationName:`"$Env:USERDOMAIN`" /IAcceptExchangeServerLicenseTerms /MdbName:$DB1 /DbFilePath:$ExDatabasesBase\DB1\DB1.DB\DB1.EDB /LogFolderPath:$ExDatabasesBase\DB1\DB1.LOG"
Start-Process $Setuppath -ArgumentList  $ArgumentLst -Wait -NoNewWindow
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name $ScriptName -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\exchange.pass`""
Restart-Computer -force
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
    [ValidateSet('sp3')]
    [alias('ex_sp')]$e14_sp,
    [Parameter(Mandatory=$false)]
    [ValidateSet('ur1','ur2','ur3','ur4','ur5','ur6','ur7','ur8v2','ur9','ur10','ur11','ur12','ur13','ur14','ur15','ur16')]
    [alias('ex_ur')]$e14_ur,
    [Parameter(Mandatory = $false)]
    [ValidateSet('de_DE','en_US')]
    [alias('e14_lang')]$ex_lang = 'de_DE',
    $ExDatabasesBase = "C:\ExchangeDatabases",
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $ex_version= "E2010",
    $Prereq ="Prereq", 
    $Setupcmd = "Setup.com"
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
$Setuppath = "$Exchange_Dir\$($ex_version)\$EX_Version$($e14_sp)\$Setupcmd"
.$Nodescriptdir\test-setup -setup $Ex_version -setuppath $Setuppath

$DB1 = "DB1_"+$env:COMPUTERNAME

start-Process $Setuppath -ArgumentList "/mode:Install /role:MB,HT,CA,MT /OrganizationName:`"$Env:USERDOMAIN`" /MdbName:$DB1 /DbFilePath:$ExDatabasesBase\DB1\DB1.DB\DB1.EDB /LogFolderPath:$ExDatabasesBase\DB1\DB1.LOG" -Wait -NoNewWindow
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

## getting cu file
if ($e14_ur)
    {
    $Llng = $ex_lang.Substring(0,2)
    $UR_Path = "$Exchange_Dir\$($ex_version)\$($e14_ur)"
    $ur_cmd = (Get-ChildItem -Path $UR_Path -Filter "*$($lang).msp").FullName
    $argument = "/update "+ '"' + $ur_cmd +'"' + " /passive"
    Start-Process -FilePath msiexec.exe -ArgumentList $argument -Wait -NoNewWindow
    }

New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name $ScriptName -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\exchange.pass`""
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

Restart-Computer -force
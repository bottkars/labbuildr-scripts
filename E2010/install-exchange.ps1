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
    [ValidateSet('sp3')]
    [alias('ex_sp')]$e14_sp,
    [Parameter(Mandatory=$false)]
    [ValidateSet('ur13')]
    [alias('ex_ur')]$e14_ur,
    $ExDatabasesBase = "C:\ExchangeDatabases",
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $ex_version= "E2010",
    $Prereq ="Prereq", 
    $Setupcmd = "Setup.com",
    $ex_lang = "de_DE"
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
$Setuppath = "$Exchange_Dir\$($ex_version)_$($ex_lang)\$EX_Version$($e14_sp)\$Setupcmd"
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
    $UR_Path = "$Exchange_Dir\$($ex_version)_$($ex_lang)\$($e14_ur)"
    $ur_cmd = (Get-ChildItem -Path $UR_Path -Filter "*.msp").FullName
    #.$ur_cmd /passive
    #$ur_cmd = "\\vmware-host\Shared Folders\Sources\Exchange\E2010_de_DE\ur13\Exchange2010-KB3141339-x64-de.msp"
    $argument = "/update "+ '"' + $ur_cmd +'"' + " /passive"
    Start-Process -FilePath msiexec.exe -ArgumentList $argument -Wait -NoNewWindow
    }

New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name $ScriptName -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\exchange.pass`""
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

Restart-Computer
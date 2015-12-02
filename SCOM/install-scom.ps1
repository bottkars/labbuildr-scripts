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
    [ValidateSet('SC2012_R2','SCTP3','SCTP4')]
    $SC_VERSION = "SC2012_R2",
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $Prereq ="Prereq",
    [string]$SysCtr = "sysctr",
    $DBInstance 
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
.$Nodescriptdir\test-sharedfolders.ps1 -Folder $Sourcepath


$Domain = $($Env:USERDOMAIN)
If (!$DBInstance)
    {
    $DBInstance = "MSSQL$Domain"
    }
$DBInstance = $DBInstance.substring(0, [System.Math]::Min(16, $DBInstance.Length))


$DBInstance="$($Env:COMPUTERNAME)\$DBInstance"
$Action_ACT = "$($Domain)\Administrator"
$DAS_ACT = "$($Domain)\SVC_SQLADM"
$Data_Reader = "$($Domain)\SVC_SQLADM"
$Data_Writer = "$($Domain)\SVC_SQLADM"
$Password = "Password123!"
$MGMTGrp = "$($Domain)Mgmt"
$Components = "OMServer,OMConsole"
$Scom_Dir = Join-Path "$SourcePath" "$SysCtr\$SC_VERSION\SCOM"
$Scom_Update_DIr = Join-Path $Sourcepath "$SysCtr\$SC_VERSION\SCOMUpdates"


$Setupcmd = "SQLSysClrTypes.msi"
$Setuppath = "$SourcePath\$Prereq\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting SQL Cleartype Setup"
Start-Process -FilePath msiexec.exe -ArgumentList "/i $Setuppath /passive" -Wait


$Setupcmd = "ReportViewer.msi"
$Setuppath = "$SourcePath\$Prereq\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting Report Viewer Setup"
Start-Process -FilePath msiexec.exe -ArgumentList "/i $Setuppath /passive" -Wait

Pause
$Setupcmd = "setup.exe"
# D:\Sources\SysCtr\SCTP4\SCOM
$Setuppath = Join-Path $Scom_Dir $Setupcmd 
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting $scom_ver setup, this may take a while"
Start-Process "$Setuppath" -ArgumentList "/install /components:$Components /ManagementGroupName:$MGMTGrp /SqlServerInstance:$DBInstance /DatabaseName:OperationsManager /DWSqlServerInstance:$DBInstance /DWDatabaseName:OperationsManagerDW /ActionAccountUser:$Action_ACT /ActionAccountPassword:$Password /DASAccountUser:$DAS_ACT /DASAccountPassword:$Password /DatareaderUser:$Data_Reader /DatareaderPassword:$Password /DataWriterUser:$Data_Writer /DataWriterPassword:$Password /EnableErrorReporting:Never /SendCEIPReports:0 /UseMicrosoftUpdate:0 /AcceptEndUserLicenseAgreement:1 /silent" -Wait
   
Write-Warning "Checking for Updates"
foreach ($Updatepattern in ("*AMD64-server.msp","*AMD64-ENU-Console.msp"))
    {
    $SCOMUpdate = Get-ChildItem $UpdateDir -Filter $Updatepattern -ErrorAction SilentlyContinue
    if ($SCOMUpdate)
        {
        $SOMUpdate = $SCOMUpdate | Sort-Object -Property Name -Descending
	    $LatestSCOMUpdate = $SCOMUpdate[0]
        .$NodeScriptDir\test-setup -setup $LatestSCOMUpdate.BaseName -setuppath $LatestSCOMUpdate.FullName
        Write-Warning "Starting SCOM Patch setup, this may take a while"
        start-process $LatestSCOMUpdate.FullName -ArgumentList "/Passive" -Wait 
        }
    }
pause
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }


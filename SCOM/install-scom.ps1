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
    [ValidateSet('SC2012_R2','SC2016')]
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
$Scom_Update_DIr = Join-Path $Scom_Dir "SCOMUpdates"


$Setupcmd = "SQLSysClrTypes.msi"
$Setuppath = "$SourcePath\$Prereq\$SC_VERSION\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting SQL Cleartype Setup"
$SetupArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $SetupArgs -PassThru -Wait


$Setupcmd = "ReportViewer.msi"
$Setuppath = "$SourcePath\$Prereq\$SC_VERSION\$Setupcmd"
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Verbose "Starting Report Viewer Setup"
$SetupArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $SetupArgs -PassThru -Wait

$Setupcmd = "setup.exe"
$Setuppath = Join-Path $Scom_Dir $Setupcmd 
.$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting $scom_ver setup, this may take a while"
Start-Process "$Setuppath" -ArgumentList "/install /components:$Components /ManagementGroupName:$MGMTGrp /SqlServerInstance:$DBInstance /DatabaseName:OperationsManager /DWSqlServerInstance:$DBInstance /DWDatabaseName:OperationsManagerDW /ActionAccountUser:$Action_ACT /ActionAccountPassword:$Password /DASAccountUser:$DAS_ACT /DASAccountPassword:$Password /DatareaderUser:$Data_Reader /DatareaderPassword:$Password /DataWriterUser:$Data_Writer /DataWriterPassword:$Password /EnableErrorReporting:Never /SendCEIPReports:0 /UseMicrosoftUpdate:0 /AcceptEndUserLicenseAgreement:1 /silent" -Wait
   
Write-Host  -ForegroundColor Magenta "Checking for Updates"
if ($SC_VERSION -match "SC2016")
	{
	foreach ($Updatepattern in ("*AMD64-Server.msp","*AMD64-ENU-Console.msp"))
    {
    Try
        {
        $SCOMUpdate = Get-ChildItem $Scom_Update_DIr  -Filter $Updatepattern -ErrorAction Stop
        }
    catch
        {
        Write-Host "No Update Found  for $Updatepattern"
        }
    if ($SCOMUpdate)
        {
        $SCOMUpdate = $SCOMUpdate | Sort-Object -Property Name -Descending
	    $LatestSCOMUpdate = $SCOMUpdate[0]
        .$Nodescriptdir\test-setup.ps1 -setup $LatestSCOMUpdate.BaseName -setuppath $LatestSCOMUpdate.FullName
        Write-Warning "Starting SCOM Patch setup, this may take a while"
        $argumentList = "/update `"$($LatestSCOMUpdate.FullName)`" /q"
        start-process  -FilePath "msiexec.exe"  -ArgumentList $argumentList -Wait -NoNewWindow
        }
    }

	}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }


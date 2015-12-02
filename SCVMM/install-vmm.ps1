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
    $DBInstance,
    [switch]$fix_ACL 
)
$Nodescriptdir = "$Scriptdir\NODE"
$EXScriptDir = "$Scriptdir\$ex_version"
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
######################################################################
$Domain = $env:USERDOMAIN
$SCVMM_Dir = Join-Path "$SourcePath" "$SysCtr\$SC_VERSION\SCVMM"
$SCVMM_Update_DIr = Join-Path $Sourcepath "$SysCtr\$SC_VERSION\SCVMMUpdates"

$Content = @()
If (!$DBInstance)
    {
    $DBInstance = "MSSQL$Domain"
    }
$DBInstance = $DBInstance.substring(0, [System.Math]::Min(16, $DBInstance.Length))
$Content = "[OPTIONS]
UserName=$Domain user
CompanyName=$Domain Eval
CreateNewSqlDatabase=1
SqlInstanceName=$DBInstance
SqlDatabaseName=VMMDB
RemoteDatabaseImpersonation=0
CreateNewLibraryShare=1
LibraryShareName=MSSCVMMLibrary
LibrarySharePath=C:\Virtual Machine Manager Library Files
LibraryShareDescription=Virtual Machine Manager Library Files
SQMOptIn = 0
MUOptIn = 0"

Set-Content  -Value $Content -Path "$logpath\VMServer.ini"
if ($SC_VERSION -match "2012")
    {
    $fix_ACL = $True
    }
$Setupcmd = "setup.exe"
$Setuppath = "$SCVMM_Dir\$Setupcmd"
.$Nodescriptdir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
Write-Warning "Starting $SC_VERSION setup, this may take a while"
# start-process "$Setuppath" -ArgumentList "/server /i /SqlDBAdminDomain $Domain /SqlDBAdminName SVC_SQL /SqlDBAdminPassword Password123! /VmmServiceDomain $Domain /VmmServiceUserName SVC_SCVMM /VmmServiceUserPassword Password123! /IACCEPTSCEULA" -Wait 
start-process "$Setuppath" -ArgumentList "/server /i /f $logpath\VMServer.ini /SqlDBAdminDomain $Domain /SqlDBAdminName SVC_SQL /SqlDBAdminPassword Password123! /VmmServiceDomain $Domain /VmmServiceUserName SVC_SCVMM /VmmServiceUserPassword Password123! /IACCEPTSCEULA" -Wait 
write-verbose "Checking for Updates"
foreach ($Updatepattern in ("*vmmserver*.msp","*Admin*.msp"))
    {
    Try
        {
        $VMMUpdate = Get-ChildItem "$SCVMM_Update_DIr"  -Filter $Updatepattern -ErrorAction Stop
        }
    catch
        {
        Write-Host "No Update Found  for $Updatepattern"
        }
    if ($VMMUpdate)
        {
        $VMMUpdate = $VMMUpdate | Sort-Object -Property Name -Descending
	    $LatestVMMUpdate = $VMMUpdate[0]
        .$Nodescriptdir\test-setup.ps1 -setup $LatestVMMUpdate.BaseName -setuppath $LatestVMMUpdate.FullName
        Write-Warning "Starting VMM Patch setup, this may take a while"
        start-process $LatestVMMUpdate.FullName -ArgumentList "/Passive" -Wait 
        }
    }
$SCVMM_Path = (get-item 'C:\Program Files\Microsoft System*\Virtual Machine Manager\bin\AddInPipeline\').FullName
if ($fix_ACL)
    {
    Write-Warning "Fixing AddIn Pipeline"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\Authenticated Users"," Write, ReadAndExecute, Synchronize", "ContainerInherit, ObjectInherit", "None", "Allow")
    $ACL = get-acl $SCVMM_Path
    $acl.SetOwner([System.Security.Principal.NTAccount] "Administrators")
    set-acl -Path $SCVMM_Path $Acl
    $acl.SetAccessRuleProtection($True, $False) 
    $Acl.AddAccessRule($rule) 
    set-acl -Path $SCVMM_Path $Acl
    }

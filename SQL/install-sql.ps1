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
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $Prereq ="Prereq",
	[ValidateSet(
    'SQL2014SP1slip','SQL2012','SQL2012SP1','SQL2012SP2','SQL2012SP1SLIP','SQL2014','SQL2016'
    )]$SQLVER,
    $Diskparameter = "",
    $DBInstance,
    $ProductDir = "SQL",
    [switch]$DefaultDBpath,
    [switch]$reboot 
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
############ adding Domin Service Accounts
$Domain = $env:USERDOMAIN
If (!$DBInstance)
    {
    $DBInstance = "MSSQL$Domain"
    }
$DBInstance = $DBInstance.substring(0, [System.Math]::Min(16, $DBInstance.Length))
$ProductDir = Join-Path $SourcePath $ProductDir
net localgroup "Backup Operators" $Domain\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SCVMM /Add
$UpdateSource = ""
Switch ($SQLVER)
    {
    'SQL2012SP1'
        {
        $SQL_BASEVER = "SQL2012"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        $UpdateSource = "/UpdateSource=`"$SQL_BASEDir\$SQLVER`""
        $Setupcmd = "setup.exe"
        $Setuppath = "$SQL_BASEDir\SQLFULL_x64_ENU\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2012SP2'
        {
        $SQL_BASEVER = "SQL2012"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        $UpdateSource = "/UpdateSource=`"$SQL_BASEDir\$SQLVER`""
        $Setupcmd = "setup.exe"
        $Setuppath = "$SQL_BASEDir\SQLFULL_x64_ENU\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2012'
        {
        $SQL_BASEVER = "SQL2012"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        $Setupcmd = "setup.exe"
        $Setuppath = "$SQL_BASEDir\SQLFULL_x64_ENU\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2012SP1Slip'
        {
        $SQL_BASEVER = "SQL2012"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        $Setupcmd = "setup.exe"
        $Setuppath = "$SQL_BASEDir\$SQLVER\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }

    'SQL2014'
        {
        $SQL_BASEVER = $SQLVER
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        $Setupcmd = "setup.exe"
        $Setuppath = "$SQL_BASEDir\$SQLVER\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2014SP1slip'
        {
        $SQL_BASEVER = "SQL2014"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        $Setupcmd = "setup.exe"
        $Setuppath = "$SQL_BASEDir\$SQLVER\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
     'SQL2016'
        {
        # NETFX Setup
        $Setupcmd = "NDP461-KB3102436-x86-x64-AllOS-ENU.exe"
        $Setuppath = "$SourcePath\$Prereq\$Setupcmd"
        .$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $Setuppath
        Start-Process $Setuppath -ArgumentList "/passive /norestart" -PassThru -Wait

        $SQL_BASEVER = "SQL2016"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        $Setupcmd = "setup.exe"
        $Setuppath = "$SQL_BASEDir\$SQLVER\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }


    }
if (!$DefaultDBpath.IsPresent)
    {
    $Diskparameter = "/SQLUSERDBDIR=m:\ /SQLUSERDBLOGDIR=n:\ /SQLTEMPDBDIR=o:\ /SQLTEMPDBLOGDIR=p:\"
    }
$Arguments = "/q /ACTION=Install /FEATURES=SQL,SSMS $UpdateSource $Diskparameter /INSTANCENAME=$DBInstance /SQLSVCACCOUNT=`"$Domain\svc_sqladm`" /SQLSVCPASSWORD=`"Password123!`" /SQLSYSADMINACCOUNTS=`"$Domain\svc_sqladm`" `"$Domain\Administrator`" `"$Domain\sql_admins`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /IACCEPTSQLSERVERLICENSETERMS"
Write-Verbose $Arguments
Write-Warning "Starting SQL Setup $SQLVER"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
$Time = Measure-Command {Start-Process $Setuppath -ArgumentList  $Arguments -Wait}
$Time | Set-Content "$logpath\sqlsetup$SQLVER.txt" -Force
If ($LASTEXITCODE -lt 0)
    {
    Write-Warning "Error $LASTEXITCODE during SQL SETUP, Please Check Installer Logfile"
    Set-Content -Value $LASTEXITCODE -Path $logpath\sqlexit.txt
    Pause
    }
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "SQLPASS" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path c:\scripts\sql.pass`""
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
if ($reboot.IsPresent)
    { 
    Restart-Computer
    }


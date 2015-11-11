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
	[ValidateSet('SQL2014SP1slip','SQL2012','SQL2012SP1','SQL2012SP2','SQL2012SP1SLIP','SQL2014')]$SQLVER,
    $Diskparameter = "",
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
.$Nodescriptdir\test-sharedfolders.ps1
############ adding Domin Service Accounts
$Domain = $env:USERDOMAIN
net localgroup "Backup Operators" $Domain\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SCVMM /Add
<#
$Files = Get-ChildItem -Path $Builddir -Filter Configuration*.ini
foreach ($file in $Files) {
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "brslab", "$Domain"} | Set-Content $file.FullName

}#>
Switch ($SQLVER)
    {
    'SQL2012SP1'
        {
        $UpdateSource = "/UpdateSource=`"$SourcePath\$SQLVER`""
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\SQLFULL_x64_ENU\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2012SP2'
        {
        $UpdateSource = "/UpdateSource=`"$SourcePath\$SQLVER`""
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\SQLFULL_x64_ENU\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    default
        {
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\$SQLVER\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
   <# 'SQL2012'
        {
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\$SQLVER\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }
    'SQL2014'
        {
        $Setupcmd = "setup.exe"
        $Setuppath = "$SourcePath\$SQLVER\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        }#>
    }
if (!$DefaultDBpath.IsPresent)
    {
    $Diskparameter = "/SQLUSERDBDIR=m:\ /SQLUSERDBLOGDIR=n:\ /SQLTEMPDBDIR=o:\ /SQLTEMPDBLOGDIR=p:\"
    }
$Arguments = "/q /ACTION=Install /FEATURES=SQL,SSMS $UpdateSource $Diskparameter /INSTANCENAME=MSSQL$Domain /SQLSVCACCOUNT=`"$Domain\svc_sqladm`" /SQLSVCPASSWORD=`"Password123!`" /SQLSYSADMINACCOUNTS=`"$Domain\svc_sqladm`" `"$Domain\Administrator`" `"$Domain\sql_admins`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /IACCEPTSQLSERVERLICENSETERMS"
Write-Verbose $Arguments
Write-Warning "Starting SQL Setup $SQLVER"
$Time = Measure-Command {Start-Process $Setuppath -ArgumentList  $Arguments -Wait}
$Time | Set-Content "$Builddir\sqlsetup$SQLVER.txt" -Force
If ($LASTEXITCODE -lt 0)
    {
    Write-Warning "Error $LASTEXITCODE during SQL SETUP, Please Check Ibstaller Logfile"
    Set-Content -Value $LASTEXITCODE -Path $Builddir\sqlexit.txt
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
# New-Item -ItemType File -Path c:\scripts\sql.pass
if ($reboot.IsPresent)
    { 
    Restart-Computer
    }


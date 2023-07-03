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
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $Prereq ="Prereq",
    [ValidateSet(#'SQL2014SP1slip','SQL2012','SQL2012SP1','SQL2012SP2','SQL2012SP1SLIP','SQL2014','SQL2016',
	#'SQL2012_ISO',
	#'SQL2014SP2_ISO',
    #'SQL2016_ISO',
    #'SQL2017_ISO',
    'SQL2019_ISO',
    'SQL2022_ISO')]$SQLVER,
	$Diskparameter = "",
    $DBInstance,
    $ProductDir = "SQL",
    [switch]$DefaultDBpath,
    [switch]$ServerCore,
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
#.$Nodescriptdir\test-sharedfolders.ps1 -Folder $Sourcepath
############ adding Domin Service Accounts
$Domain = $env:USERDOMAIN
if (!($DefaultDBpath.IsPresent))
    {
	.$Builddir\prepare-disks.ps1
    }
If (!$DBInstance)
    {
    $DBInstance = "MSSQL$Domain"
    }
$DBInstance = $DBInstance.substring(0, [System.Math]::Min(16, $DBInstance.Length))
# $ProductDir = Join-Path $SourcePath $ProductDir
net localgroup "Backup Operators" $Domain\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SQLADM /Add
net localgroup "Administrators" $DOMAIN\SVC_SCVMM /Add
$UpdateSource = ""
$Features = 'SQL,SSMS'

Switch ($SQLVER)
    {
<#    'SQL2012SP1'
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
        Write-Host -ForegroundColor Magenta " ==> Installing NetFramework"
        .$NodeScriptDir\install-netframework.ps1 -net_ver 461
        Write-Host -ForegroundColor Magenta " ==> Installing Java"
        .$NodeScriptDir\install-java.ps1 -java_ver 8
        $SQL_BASEVER = "SQL2016"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        Write-Host -ForegroundColor Magenta " ==> Installing SQL Server Management Studio"
        $Setupcmd = 'SSMS-Setup-ENU.exe'
        $Setuppath = "$SQL_BASEDir\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        $Arguments = "/install /passive /norestart"
        Start-Process $Setuppath -ArgumentList  $Arguments -Wait
        $Setupcmd = "setup.exe"
        $Setuppath = "$SQL_BASEDir\$SQLVER\$Setupcmd"
        .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
        $Features = 'SQL,Tools,Polybase'
        $Java_required  = $true
        }#>
    'SQL2019_ISO'
        {
        $SQL_BASEVER = "SQL2019"
            $Features = 'SQL' #,Polybase'
	$FSLABEL="SqlSetup_x64_ENU    
        } 
    'SQL2022_ISO'
        {
        $SQL_BASEVER = "SQL2022"
            $Features = 'SQL' #,Polybase'
	$FSLABEL = "SQLServer2022"   
        } 
	
<#
        'SQL2017_ISO'
        {
		$Iso_File = "SQLServer2017-x64-ENU.iso"
        Write-Host -ForegroundColor Magenta " ==> Installing NetFramework"
        .$NodeScriptDir\install-netframework.ps1 -net_ver 461 -sourcepath $sourcepath
        Write-Host -ForegroundColor Magenta " ==> Installing Java"
        .$NodeScriptDir\install-java.ps1 -java_ver 8 -sourcepath $sourcepath
        $SQL_BASEVER = "SQL2017"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        if (!$ServerCore.ispresent)
            {
            Write-Host -ForegroundColor Magenta " ==> Installing SQL Server Management Studio"
            $Setupcmd = 'SSMS-Setup-ENU.exe'
            $Setuppath = "$SQL_BASEDir\$Setupcmd"
            .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
            $Arguments = "/install /passive /norestart"
            Start-Process $Setuppath -ArgumentList  $Arguments -Wait -PassThru
            $Features = 'SQL,Tools,Polybase'
            $Java_required  = $true
            }
        else 
            {
            $Features = 'SQL,Polybase'
            $Java_required  = $true
            }
        }        
      'SQL2016_ISO'
        {
		$Iso_File = "SQLServer2016-x64-ENU.iso"
        Write-Host -ForegroundColor Magenta " ==> Installing NetFramework"
        .$NodeScriptDir\install-netframework.ps1 -net_ver 461 -sourcepath $sourcepath
        Write-Host -ForegroundColor Magenta " ==> Installing Java"
        .$NodeScriptDir\install-java.ps1 -java_ver 8 -sourcepath $sourcepath
        $SQL_BASEVER = "SQL2016"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        if (!$ServerCore.ispresent)
            {
            Write-Host -ForegroundColor Magenta " ==> Installing SQL Server Management Studio"
            $Setupcmd = 'SSMS-Setup-ENU.exe'
            $Setuppath = "$SQL_BASEDir\$Setupcmd"
            .$NodeScriptDir\test-setup -setup $Setupcmd -setuppath $Setuppath
            $Arguments = "/install /passive /norestart"
            Start-Process $Setuppath -ArgumentList  $Arguments -Wait -PassThru
            $Features = 'SQL,Tools,Polybase'
            $Java_required  = $true
            }
        else 
            {
            $Features = 'SQL,Polybase'
            $Java_required  = $true
            }
        }
	    'SQL2012_ISO'
        {
		$Iso_File = "SQLFULL_ENU.iso"
        $SQL_BASEVER = "SQL2012"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        $Features = 'SQL,Tools'
        }
		'SQL2014SP2_ISO'
        {
		$Iso_File = "SQLServer2014SP2-FullSlipstream-x64-ENU.iso"
        $SQL_BASEVER = "SQL2014"
        $SQL_BASEDir = Join-Path $ProductDir $SQL_BASEVER
        $Features = 'SQL,Tools'
        }
        #>
    }

#$Isopath = Join-path $SQL_BASEDir $Iso_File
#Write-Verbose $Isopath
#.$Nodescriptdir\test-setup -setup $SQL_BASEVER -setuppath $Isopath
#if (!(Test-Path "$env:USERPROFILE\Downloads\$Iso_File"))
#	{
#	Write-Host -ForegroundColor Gray "Copying $SQL_BASEVER ISO locally"
#	Copy-Item $Isopath -Destination "$env:USERPROFILE\Downloads"
#	}
#$Temp_Iso = "$env:USERPROFILE\Downloads\$Iso_File"
#$ismount = Mount-DiskImage -ImagePath $Temp_Iso -PassThru
$Driveletter = (Get-Volume | where FileSystemLabel -eq "$($FSLABEL)").DriveLetter
$Setupcmd = "setup.exe"
$Setuppath = "$($Driveletter):\$Setupcmd" 
if (!($DefaultDBpath.IsPresent))
    {
    $Diskparameter = "/SQLUSERDBDIR=m:\ /SQLUSERDBLOGDIR=n:\ /SQLTEMPDBDIR=o:\ /SQLTEMPDBLOGDIR=p:\"
    }
$Arguments = "/q /ACTION=Install /FEATURES=$Features $UpdateSource $Diskparameter /INSTANCENAME=$DBInstance /SQLSVCACCOUNT=`"$Domain\svc_sqladm`" /SQLSVCPASSWORD=`"Password123!`" /SQLSYSADMINACCOUNTS=`"$Domain\svc_sqladm`" `"$Domain\Administrator`" `"$Domain\sql_admins`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /IACCEPTSQLSERVERLICENSETERMS"
Write-Verbose $Arguments
Write-Host -ForegroundColor Magenta " ==> Installing SQL Server"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
$Time = Measure-Command {Start-Process $Setuppath -ArgumentList  $Arguments -Wait -NoNewWindow}
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
    Restart-Computer -force
    }

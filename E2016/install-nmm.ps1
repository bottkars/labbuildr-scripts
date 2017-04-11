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
    [ValidateSet(
	'nmm9100','nmm9102','nmm9103','nmm9104','nmm9105',#-#
    'nmm9010','nmm9011','nmm9012','nmm9013','nmm9014','nmm9015','nmm9016',#
    'nmm90.DA','nmm9001','nmm9002','nmm9003','nmm9004','nmm9005','nmm9006','nmm9007','nmm9008',
	'nmm8240','nmm8241','nmm8242','nmm8243','nmm8244',#-#
    'nmm230','nmm8231','nmm8232','nmm8233','nmm8235','nmm8236','nmm8237','nmm8238',
    'nmm8221','nmm8222','nmm8223','nmm8224','nmm8225','nmm8226',
    'nmm8218','nmm8217','nmm8216','nmm8214','nmm8212','nmm8210'
    )]
    $nmm_ver,
    $nmmusername = "NMMBackupUser",
    $nmmPassword = "Password123!",
    $nmmdatabase = "DB1_$Env:COMPUTERNAME",
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
$Nodescriptdir = Join-Path $Scriptdir "Node"
$NWScriptDir = Join-Path $Scriptdir "nwserver"
$SourcePath = Join-Path $SourcePath "Networker"
$EXScriptDir = Join-Path $Scriptdir "$ex_version"
$Domain = $env:USERDNSDOMAIN
Write-Verbose $Domain
.$Nodescriptdir\test-sharedfolders.ps1 -Folder $SourcePath
if ($Nmm_ver -lt 'nmm85')
    {
    $Setuppath = "$SourcePath\$nmm_ver\win_x64\networkr\setup.exe" 
    .$Nodescriptdir\test-setup -setup NMM -setuppath $Setuppath
    $argumentlist = '/s /v" /qn /l*v c:\scripts\nmm.log RMEXCHDOMAIN='+$Domain+' RMEXCHUSER=NMMBackupUser RMEXCHPASSWORD=Password123! RMCPORT=6730 RMDPORT=6731"'
    start-process -filepath $Setuppath -ArgumentList $argumentlist -wait -PassThru
    }
else
    {
    $Setuppath = "$SourcePath\$nmm_ver\win_x64\networkr\nwvss.exe" 
    .$Nodescriptdir\test-setup -setup NMM -setuppath $Setuppath
	if ($nmm_ver -ge 'nmm9010')
		{
		$argumentlist = "/s /q /log `"C:\scripts\NMM_nw_install_detail.log`" InstallLevel=200 RebootMachine=0 NwGlrFeature=1 EnableExchangeGLR=1 EnableClientPush=1 WriteCacheFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\nwfs`" MountPointFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\nwfs\NetWorker Virtual File System`" BBBMountPointFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\BBBMountPoint`" SetupType=Install"
		}
	else
		{
		$argumentlist = "/s /q /log `"C:\scripts\NMM_nw_install_detail.log`" InstallLevel=200 RebootMachine=0 NwGlrFeature=1 EnableClientPush=1 WriteCacheFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\nwfs`" MountPointFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\nwfs\NetWorker Virtual File System`" BBBMountPointFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\BBBMountPoint`" SetupType=Install"
		}
    Start-Process -Wait -FilePath $Setuppath -ArgumentList $argumentlist
	#Write-Verbose "Configuring NMM Backup User"
    #Start-Process -Wait -FilePath "C:\Program Files\EMC NetWorker\nsr\bin\UserConfigCLI.exe"  -ArgumentList "$nmmusername $nmmPassword $nmmdatabase"
    }
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

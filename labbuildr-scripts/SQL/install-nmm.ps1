﻿<#
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
    [ValidateSet(
    'nmm9211','nmm9210',#-#    
    'nmm9201','nmm9203',#-#    
    'nmm9111','nmm9112','nmm9113','nmm9114','nmm9115',#-#   
	'nmm9100','nmm9102','nmm9103','nmm9104','nmm9105','nmm9106',#-#
    'nmm9010','nmm9011','nmm9012','nmm9013','nmm9014','nmm9015','nmm9016','nmm9017','nmm9018','nmm9019',#
    'nmm90.DA','nmm9001','nmm9002','nmm9003','nmm9004','nmm9005','nmm9006','nmm9007','nmm9008',
	'nmm8240','nmm8241','nmm8242','nmm8243','nmm8244','nmm8245','nmm8246','nmm8248','nmm8249','nmm82410',#-#
	'nmm230','nmm8231','nmm8232','nmm8233','nmm8235','nmm8236','nmm8237','nmm8238',
    'nmm8221','nmm8222','nmm8223','nmm8224','nmm8225','nmm8226',
    'nmm8218','nmm8217','nmm8216','nmm8214','nmm8212','nmm8210',
    'nmmunknown'
    )]
    $nmm_ver,
    [switch]$scvmm
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
############
$Nodescriptdir = Join-Path $Scriptdir "Node"
$NWScriptDir = Join-Path $Scriptdir "nwserver"
$SourcePath = Join-Path $SourcePath "Networker"

$Domain = $env:USERDOMAIN
Write-Verbose $Domain

.$Nodescriptdir\test-sharedfolders.ps1 -Folder $SourcePath
switch ($nmm_ver)
    {
    {($_ -lt 'nmm85')}
        {
        $Setuppath = "$Sourcepath\$nmm_ver\win_x64\networkr\setup.exe" 
        .$Nodescriptdir\test-setup -setup NMM -setuppath $Setuppath
        Write-Host -ForegroundColor Magenta " ==> Doing NMM Base Install"
        start-process -filepath "$Setuppath" -ArgumentList '/s /v" /qn /L*v c:\scripts\nmm.log'  -Wait -PassThru
        Write-Host -ForegroundColor Magenta " ==> Doing NWVSS Install"
        start-process -filepath "$Setuppath" -ArgumentList '/s /v" /qn /L*v c:\scripts\nmmglr.log NW_INSTALLLEVEL=200 REBOOTMACHINE=0 NW_GLR_FEATURE=1 WRITECACHEDIR="C:\Program Files\EMC NetWorker\nsr\tmp\nwfs" MOUNTPOINTDIR="C:\Program Files\EMC NetWorker\nsr\tmp\nwfs\NetWorker Virtual File System" HYPERVMOUNTPOINTDIR="C:\Program Files\EMC NetWorker\nsr\tmp" SETUPTYPE=Install"' -Wait -PassThru
    #    Write-Host -ForegroundColor Magenta " ==> Doing SSMS Plugin Install"
    #    start-process -filepath "$Setuppath" -ArgumentList '/s /v" /qn /L*v c:\scripts\nmmglr.log INSTALLLEVEL=150 SETUPTYPE=Install INSTCLIENTPUSH=1 RMCPORT=6728 RMDPORT=6729 NW_SSMS_FEATURE=1"' -Wait -PassThru
        }
    {($_ -ge 'nmm85') -and ($_ -lt 'nmm92')}
        {
        $Setuppath = "$Sourcepath\$nmm_ver\win_x64\networkr\nwvss.exe" 
        .$Nodescriptdir\test-setup -setup NMM -setuppath $Setuppath
        Start-Process -Wait -FilePath $Setuppath -ArgumentList "/s /q /log `"C:\scripts\NMM_nw_install_detail.log`" InstallLevel=200 RebootMachine=0 EnableSSMS=1 EnableSSMSBackupTab=1 EnableSSMSScript=1 NwGlrFeature=1 EnableClientPush=1 WriteCacheFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\nwfs`" MountPointFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\nwfs\NetWorker Virtual File System`" BBBMountPointFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\BBBMountPoint`" SetupType=Install"
        }
    {($_ -ge 'nmm92')}
        {
            $Setuppath = "$Sourcepath\$nmm_ver\win_x64\networkr\nwvss.exe" 
            .$Nodescriptdir\test-setup -setup NMM -setuppath $Setuppath
            Start-Process -Wait -FilePath $Setuppath -ArgumentList "/s /q /log `"C:\scripts\NMM_nw_install_detail.log`" InstallLevel=150 RebootMachine=0 EnableSSMS=1 BBBMountPointFolder=`"C:\Program Files\EMC NetWorker\nsr\tmp\BBBMountPoint`" SetupType=Install"
            
        }
}   


if ($scvmm.IsPresent)
    {
    if ($nmm_ver -ge "nmm85" )
        {
        Write-Verbose "Installing Networker Extended Client" 
        $nw_ver = $nmm_ver -replace "nmm","nw"
        $Setuppath = "$Sourcepath\$nw_ver\win_x64\networkr\lgtoxtdclnt-8.5.0.0.exe" 
        .$Nodescriptdir\test-setup -setup lgtoxtdclnt-8.5.0.0 -setuppath $Setuppath
        Start-Process $Setuppath -ArgumentList "/q" -Wait
        }
    $SCVMMPlugin = $NMM_VER -replace "nmm","scvmm"
    $Setuppath = "$Sourcepath\$SCVMMPlugin\win_x64\SCVMM DP Add-in.exe" 
    .$Nodescriptdir\test-setup -setup NMM -setuppath $Setuppath
    Start-Process $Setuppath -ArgumentList "/q" -Wait
    }

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

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
    'nmm9111',#-#   
	'nmm9100','nmm9102','nmm9103','nmm9104','nmm9105','nmm9106',#-#
    'nmm9010','nmm9011','nmm9012','nmm9013','nmm9014','nmm9015','nmm9016',#
    'nmm90.DA','nmm9001','nmm9002','nmm9003','nmm9004','nmm9005','nmm9006','nmm9007','nmm9008',
	'nmm8240','nmm8241','nmm8242','nmm8243','nmm8244','nmm8246',#-#
	'nmm230','nmm8231','nmm8232','nmm8233','nmm8235','nmm8236','nmm8237','nmm8238',
    'nmm8221','nmm8222','nmm8223','nmm8224','nmm8225','nmm8226',
    'nmm8218','nmm8217','nmm8216','nmm8214','nmm8212','nmm8210',
    'nmmunknown'
    )]
    $nmm_ver,
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts"

)
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


.$Builddir\test-sharedfolders.ps1 -folder $SourcePath
$Setuppath = (Join-Path $SourcePath "$nmm_ver\win_x64\networkr\setup.exe") 
.$Builddir\test-setup -setup NMM -setuppath $Setuppath

start-process -filepath "$Setuppath" -ArgumentList '/s /v" /qn /l*v c:\scripts\nmm.log"' -wait # -verb "RunAs" | Out-Host

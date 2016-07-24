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
    [ValidateSet(
    'nw9010',
    'nw90.DA','nw9001','nw9002','nw9003','nw9004','nw9005','nw9006','nw9007','nw9008',
    'nw8232','nw8231',
    'nw8226','nw8225','nw8224','nw8223','nw8222','nw8221','nw822',
    'nw8218','nw8217','nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821',
    'nw8206','nw8205','nw8204','nw8203','nw8202','nw82',
    'nw8138','nw8137','nw8136','nw8135','nw8134','nw8133','nw8132','nw8131','nw813',
    'nw8127','nw8126','nw8125','nw8124','nw8123','nw8122','nw8121','nw812',
    'nw8119','nw8118','nw8117','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',
    'nw8105','nw8104','nw8103','nw8102','nw81',
    'nw8044','nw8043','nw8042','nw8041',
    'nw8037','nw8036','nw8035','nw81034','nw8033','nw8032','nw8031',
    'nw8026','nw8025','nw81024','nw8023','nw8022','nw8021',
    'nw8016','nw8015','nw81014','nw8013','nw8012',
    'nw8007','nw8006','nw8005','nw81004','nw8003','nw8002','nw80',
    'nwunknown'
    )]
    $nw_ver,
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
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
############
$Nodescriptdir = "$Scriptdir\Node"
$NWScriptDir = "$Scriptdir\nwserver"
$SourcePath = Join-Path $SourcePath "Networker"
.$NodeScriptDir\test-sharedfolders.ps1 -Folder $SourcePath
$Setuppath = "$SourcePath\$NW_ver\win_x64\networkr\"
.$NodeScriptDir\test-setup -setup NetworkerClient -setuppath $Setuppath


if ($NW_ver -lt 'nw85')
    {
    start-process -filepath "$Setuppath\setup.exe" -ArgumentList '/S /v" /passive /l*v c:\scripts\nwclientsetup.log NW_INSTALLLEVEL=100 NW_FIREWALL_CONFIG=1 INSTALLBBB=1 NWREBOOT=0 setuptype=Install"' -wait 
    }
else
    {
    Write-Warning "Installing Modern Networker Client Version $nw_ver"
    Write-Warning "evaluating setup version"
    if ($setup = Get-ChildItem "$Sourcepath\$NW_ver\win_x64\networkr\networker-*")
        {
        Write-Warning "Starting Install"
        Start-Process -Wait -FilePath "$($Setup.fullname)" -ArgumentList "/s /v InstallLevel=100 ConfigureFirewall=1 StartServices=1 EnablePs=1 InstallBbb=1"
        }
    else
        {
        Write-Error "Networker Setup File could not be elvaluated"
        }
    }

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

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
    [ValidateSet('nw8222','nw8221','nw822','nw8218','nw8217','nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81','nw85','nw85.BR1','nw85.BR2','nw85.BR3','nw85.BR4','nw90.DA','nw9001','nwunknown')]
    $nw_ver,
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts"
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

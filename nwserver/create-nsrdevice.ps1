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
    [string]$AFTD = "aftd1",
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $Prereq ="Prereq"
     
)
$Nodescriptdir = "$Scriptdir\Node"
$NWScriptDir = "$Scriptdir\nwserver"
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
$Domain = $env:USERDOMAIN
$devicepath = Join-Path "C:\" $AFTD
new-item -Type  Directory -Path $devicepath
New-SmbShare -Description "$AFTD Direct Access" -Path $devicepath -Name $AFTD -FullAccess "$Domain\Domain Users","$Domain\Domain Computers"
$device = Get-ChildItem -Path $NWScriptDir -Filter nsrdevice.txt
$content = Get-Content -path $device.fullname
$Devicefile = Join-Path "$logpath" "$AFTD.txt"
$content | foreach {$_ -replace "AFTD", "$AFTD"} | Set-Content $Devicefile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $Devicefile

<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>
#requires -version 3
[CmdletBinding()]
param(
    [string]$ddname = "ddvenode1",
    [string]$Community = "networker",
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

$device = Get-ChildItem -Path $NWScriptDir -Filter dd.txt
$content = Get-Content -path $device.fullname
$Devicefile = Join-Path "$LogPath" "$ddname.txt"
$content | foreach {$_ -replace "ddvenode1", "$ddname"} | Set-Content $Devicefile
$pool = Get-ChildItem -Path $NWScriptDir -Filter ddpool.txt
$content = Get-Content -path $pool.fullname
$poolfile = Join-Path "$LogPath" "$ddname.pool.txt"
$content | foreach {$_ -replace "ddvenode1", "$ddname"} | Set-Content $poolfile
$label = Get-ChildItem -Path $NWScriptDir -Filter ddlabel.txt
$content = Get-Content -path $label.fullname
$labelfile = Join-Path "$LogPath" "$ddname.label.txt"
$content | foreach {$_ -replace "ddvenode1", "$ddname"} | Set-Content $labelfile
$snmp = Get-ChildItem -Path $NWScriptDir -Filter ddsnmp.txt
$content = Get-Content -path $snmp.fullname
$snmpfile = Join-Path "$LogPath" "$ddname.snmp.txt"
$content | foreach {$_ -replace "ddvenode1", "$ddname"} 
$content | foreach {$_ -replace "networker", "$Community"} | Set-Content $snmpfile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $labelfile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $Devicefile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $poolfile
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $snmpfile

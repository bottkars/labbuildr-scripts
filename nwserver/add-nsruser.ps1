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
    [Parameter(mandatory = $true)]$BackupAdmin,
    [Parameter(mandatory = $true)]$Hostprefix,
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
foreach ($Client in (Get-ADComputer -Filter * | where name -match "$Hostprefix*").DNSHostname) 
{ 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=$BackupAdmin,host=$Client"
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=SYSTEM,host=$Client"
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=Administrator,host=$Client"
}

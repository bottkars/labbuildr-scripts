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
    #[Parameter(mandatory=$true)][string]$client,
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

$Domain = $Env:USERDNSDOMAIN.tolower()
$execfile = "$logpath\renderlog.nsr"


$Content = '
print type: NSR log; name: daemon.raw
update runtime rendered log: "C:\\Program Files\\EMC Networker\\nsr\\logs\\daemon.log"
print type: NSR log; name: nsrnmmsv.raw
update runtime rendered log: "C:\\Program Files\\EMC Networker\\nsr\\applogs\\nsrnmmsv.log"
print type: NSR log; name: nsrnmmra.raw
update runtime rendered log: "C:\\Program Files\\EMC Networker\\nsr\\applogs\\nsrnmmra.log"
'
Set-Content -Path $execfile -Value $Content
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -p nsrexec -i $execfile

restart-service nsrexecd -Force 

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
$Domain = (get-addomain).name
foreach ($Client in (Get-ADComputer -Filter *).DNSHOSTname)
{
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=SYSTEM,host=$Client"
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=Administrator,host=$Client"
}


foreach ($Client in (Get-ADComputer -Filter * | where name -match "E2013*").DNSHostname) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=NMMBAckupUser,host=$Client"
}

foreach ($Client in (Get-ADComputer -Filter * | where name -match "DAG").DNSHostname) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=NMMBAckupUser,host=$Client"
}

foreach ($SID in (Get-ADGroup -Filter * | where name -eq "Administrators").SID.Value) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "Group=Administrators,Groupsid=$SID"
}

foreach ($Client in (Get-ADComputer -Filter * | where name -match "AAG*").DNSHostname) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=SVC_SQLADM,host=$Client"
}

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
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=nwadmin,host=$Client"
}
$DC = split-path -leaf $env:LOGONSERVER
### get dc language
$Computername = $DC
$dclanguage = (Get-WmiObject Win32_OperatingSystem -ComputerName $Computername ).oslanguage
        switch ($dclanguage) `
        {

            1031 
            {
            Write-Host -ForegroundColor Magenta  "==> we have a German DC, adjusting Groupnames"
            $Adminuser = "Administratoren"
            }

            default 
            {
            $Adminuser = "Administrators"
            }
        }



foreach ($Client in (Get-ADComputer -Filter * | where name -match "E201*").DNSHostname) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=DPSBackupUser,host=$Client"
}

foreach ($Client in (Get-ADComputer -Filter * | where name -match "DAG").DNSHostname) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=DPSBackupUser,host=$Client"
}

foreach ($SID in (Get-ADGroup -Filter * | where name -eq $Adminuser).SID.Value) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "Group=$Adminuser,Groupsid=$SID"
}

foreach ($Client in (Get-ADComputer -Filter * | where name -match "AAG*").DNSHostname) { 
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsraddadmin.exe'  -u "user=SVC_SQLADM,host=$Client"
}

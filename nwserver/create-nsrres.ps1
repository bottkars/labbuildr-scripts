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
    $logpath = "$NWScriptDir",
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
$Domain = (get-addomain).name.tolower()
$DomainController = (get-addomain).InfrastructureMaster.tolower()
$DAGNAME = $Domain+"dag"
$Dag = Get-ChildItem -Path $NWScriptDir -Filter client*dag.txt

foreach  ($file in $DAG) {
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "brslab", "$Domain"} | Set-Content $file.FullName
$content | foreach {$_ -replace "BRS2GODAG", "$DAGNAME"}  | Set-Content $file.FullName
}
$groups = Get-ChildItem -Path $NWScriptDir -Filter group*.txt
foreach  ($file in $groups) {
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "brslab", "$Domain"} | Set-Content $file.FullName
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $file.FullName | out-host
}

$Clients = Get-ChildItem -Path $NWScriptDir -Filter client*.txt
foreach  ($file in $Clients) {
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "brslab", "$Domain"} | Set-Content $file.FullName
$content = Get-Content -path $File.fullname
$content | foreach {$_ -replace "BRSDC", "$DomainController"} | Set-Content $file.FullName
& 'C:\Program Files\EMC NetWorker\nsr\bin\nsradmin.exe' -i $file.FullName | out-host
}

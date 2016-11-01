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
param (

)

function Createvolume {
param ($Number,$Label,$letter)
Set-Disk -Number $Number -IsReadOnly  $false 
Set-Disk -Number $Number -IsOffline  $false
Clear-Disk -Number $Number -RemoveData -RemoveOEM -Confirm:$false -ErrorAction SilentlyContinue
Write-Host " ==> Initializing Disk $Number"
Initialize-Disk -Number $Number -PartitionStyle GPT 
Write-Host " ==> Partitioning $Number"
$Partition = New-Partition -DiskNumber $Number -UseMaximumSize 
Write-Host " ==> Formatting Disk $Number"
$Job = Format-Volume -Partition $Partition -NewFileSystemLabel $Label -AllocationUnitSize 64kb -FileSystem NTFS -Force -AsJob
while ($JOB.state -ne "completed"){}
$Partition | Set-Partition -NewDriveLetter $letter
}

$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"
###########
Createvolume -Number 1 -Label $env:COMPUTERNAME"_DATA" -letter M
Createvolume -Number 2 -Label $env:COMPUTERNAME"_LOG" -letter N
Createvolume -Number 3 -Label $env:COMPUTERNAME"_TEMPDB" -letter O
Createvolume -Number 4 -Label $env:COMPUTERNAME"_TEMPLOG" -letter P

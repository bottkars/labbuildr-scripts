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
$ex_version= "E2013",
$Prereq ="Prereq",
$ExDatabasesBase = "C:\ExchangeDatabases",
$ExVolumesBase = "C:\ExchangeVolumes" 
)
$Nodescriptdir = "$Scriptdir\NODE"
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
New-Item -ItemType Directory  $ExVolumesBase
New-Item -ItemType Directory  $ExDatabasesBase
$Vol = 1
$Disks = Get-Disk  | where OperationalStatus -eq "offline" | Sort-Object
Write-Host $Disks
$Vol = 1
foreach ($Disk in $Disks)
        {
        $Disk | Set-Disk -IsReadOnly  $false 
        $Disk | Set-Disk -IsOffline  $false
        $Disk | Initialize-Disk -PartitionStyle GPT
        $Partition = $Disk | New-Partition -UseMaximumSize
        $Partition | Set-Partition -NoDefaultDriveLetter:$true
        $Job = Format-Volume -Partition $Partition -NewFileSystemLabel $Label -AllocationUnitSize 64kb -FileSystem NTFS -Force -AsJob
        while ($JOB.state -ne "completed"){}
        $VolumeMountpoint = New-Item -ItemType Directory -Path "$ExVolumesBase\Volume$Vol"
        $Partition | Add-PartitionAccessPath  -AccessPath "$ExVolumesBase\Volume$Vol"
        $Partition | Set-Partition -NoDefaultDriveLetter:$true
        if ($Disk -ne $Disks[-1])
            {
            $DataBaseMountpoint = New-Item -ItemType Directory -Path "$ExDatabasesBase\DB$vol" 
            $Partition | Add-PartitionAccessPath  -AccessPath "$ExDatabasesBase\DB$vol"
            New-Item -Name "DB$Vol.DB" -ItemType Directory -Path $DataBaseMountpoint
            New-Item -Name "DB$Vol.LOG" -ItemType Directory -Path $DataBaseMountpoint
            $Partition | Set-Partition -NoDefaultDriveLetter:$true
            }
        Write-Output $Disk
        Write-Verbose $Vol
        Write-Output $Drive
        $Vol ++
        }
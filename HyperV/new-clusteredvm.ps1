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
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",

    [string]$vmname = "HV-VM1",
    [string]$sourcevhd = "$SourcePath\HyperV\9600.16415.amd64fre.winblue_refresh.130928-2229_server_serverdatacentereval_en-us.vhd",
    [string]$Clustervolume = "C:\ClusterStorage\Volume1"

)
$Nodescriptdir = "$Scriptdir\NODE"
$EXScriptDir = "$Scriptdir\$ex_version"
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
######################################################################
if (!(Test-Path $sourcevhd))
    {
    Write-Warning "Source VHD $sourcevhd does not exist, please download a Source VHD"
    break
    }

if  (get-vm $vmname -erroraction silentlycontinue)
    {
    Write-Warning "VM $vmname already exists"
    break
    }



if (!(Test-Path "$Clustervolume\vhds\$vmname"))
    {
    New-Item -ItemType Directory -Path "$Clustervolume\$vmname\" -Force
    }
Write-Warning "Copyig VHD File $Sourcevhd to $Clustervolume, This may Take a While"
$Targetfile = Copy-Item $sourcevhd -Destination "$Clustervolume\$vmname\$vmname.vhd" -PassThru

$NewVM = New-VM -Name $vmname -Path $Clustervolume -Memory 512MB  -VHDPath $Targetfile.FullName -SwitchName External
$NewVM | Set-VMMemory -DynamicMemoryEnabled $true -MinimumBytes 128MB -StartupBytes 512MB -MaximumBytes 2GB -Priority 80 -Buffer 25
$NewVM | Get-VMHardDiskDrive | Set-VMHardDiskDrive -MaximumIOPS 2000
$Newvm | Set-VM –AutomaticStartAction Start
$NewVM | Add-ClusterVirtualMachineRole 
$NewVM | start-vm
$NewVM | Get-VM

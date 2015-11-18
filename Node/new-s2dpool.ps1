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
    $logpath = "c:\Scripts"
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
######################################################################
# Test-Cluster –Node GenNode1, GenNode2, GenNode3, GenNode4–Include “Storage Spaces Direct”,Inventory,Network,”System Configuration”

Enable-ClusterStorageSpacesDirect
$Domain = $env:USERDOMAIN
$FQDN = $env:USERDNSDOMAIN
$ClusterName = (Get-Cluster .).Name
$Clusterfqdn = "$ClusterName.$FQDN"
$StorageSubSystem = Get-StorageSubSystem -Name $Clusterfqdn

$StorageSubSystem | New-StoragePool  -FriendlyName "$Domain-Pool1" -WriteCacheSizeDefault 0 -ProvisioningTypeDefault Fixed -ResiliencySettingNameDefault Mirror -PhysicalDisk ($StorageSubSystem | Get-PhysicalDisk)
# Get-StoragePool Pool1 | Get-PhysicalDisk |? MediaType -eq SSD | Set-PhysicalDisk -Usage Journal
$Sotragepool | New-Volume -FriendlyName VDISK1 -PhysicalDiskRedundancy 1 -FileSystem CSVFS_REFS –Size 50GB
$Storagepool | New-VOlume -FriendlyName VDISK2 -PhysicalDiskRedundancy 2 -FileSystem CSVFS_REFS –Size 50GB
$Storagepool | New-Volume -FriendlyName VDISK3 -PhysicalDiskRedundancy 1 -FileSystem CSVFS_REFS –Size 50GB -ResiliencySettingName Parity
$Storagepool | New-Volume -FriendlyName VDISK4 -PhysicalDiskRedundancy 2 -FileSystem CSVFS_REFS -Size 50GB -ResiliencySettingName Parity
#Set-FileIntegrity C:\ClusterStorage\Volume1 –Enable $false
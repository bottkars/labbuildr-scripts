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
param (
$Folder = "\\vmware-host\shared folders"
)
do {

    $Enabled = Test-Path $folder
    if ($Enabled -notmatch $True)
        { 
        write-warning "Shared folders $Folder not available."
        write-warning "Script will continue once enabled"
        $([char]7)
        Start-Sleep -Seconds 5
        }
    }
until ($Enabled -match $true)
write-warning "Shared-Folders are enabled"

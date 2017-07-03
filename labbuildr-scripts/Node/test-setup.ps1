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
[parameter(Mandatory = $true)]$setup,
[parameter(Mandatory = $true)]$setuppath

)
do {

    $pathok = Test-Path $Setuppath
    if ($pathok -notmatch $True)
        { 
        write-warning "we can not find $setup Sources $Setuppath ! Make sure the you have downloaded the required sources"
        write-warning "Script will continue once the required $setup Sources are in available "
        pause
        }
    }
until ($pathok -match $true)
Write-Host -ForegroundColor Magenta "found $setuppath"

<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr builds your on-demand labs
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>

[CmdletBinding()]
param (
[string]$Computername = "."
)
#requires -version 3

$Host.UI.RawUI.WindowTitle = "$Computername"
do {Get-EventLog -LogName Application -Newest 20 -ComputerName $Computername -Source VSS,Networker,Nmm | Sort-Object Time -Descending | ft Time, EntryType, Source, Message -AutoSize; sleep 5 ;Clear-Host } 
until ($false)

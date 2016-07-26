<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>


$Nodes = Get-ClusterNode
foreach ($node in $nodes)
{

Start-Process powershell.exe -ArgumentList ".\watch-backupevents.ps1 -Computername $($Node.Name)" -WindowStyle Normal
}

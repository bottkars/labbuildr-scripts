<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr builds your on-demand labs
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>


$Nodes = Get-ClusterNode
foreach ($node in $nodes)
{

Start-Process powershell.exe -ArgumentList ".\watch-backupevents.ps1 -Computername $($Node.Name)" -WindowStyle Normal
}

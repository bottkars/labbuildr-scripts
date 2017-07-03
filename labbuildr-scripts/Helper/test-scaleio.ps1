<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr builds your on-demand labs
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>
#requires -version 3
param (
[Parameter(mandatory = $false)]$Tpath = "c:\clusterstorage\volume1\io.dat",
[Parameter(mandatory = $false)]$Tsec = 60,
[Parameter(mandatory = $false)]$TThread = 18
)
Invoke-Expression "C:\diskspd\diskspd.exe -b8K -d$Tsec -h -L -o2 -t$TThread -c100M $Tpath"
# Invoke-Expression "C:\diskpd\diskspd.exe -b8K -d3600 -h -L -o2 -t4 -r -w30 -c50M c:\clusterstorage\volume1\io.dat"

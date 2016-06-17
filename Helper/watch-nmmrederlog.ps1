<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>

[CmdletBinding()]
param (
[Parameter(Mandatory = $true)][ValidateSet('nsrnmmsv','nsrnmmra','daemon')][string[]]$Logfiles
)
#requires -version 3



foreach($log in $Logfiles)
    {
    $Logpath = 'C:\Program Files\EMC NetWorker\nsr\applogs'
    if ($log -eq 'daemon')
        {
        $Logpath = 'C:\Program Files\EMC NetWorker\nsr\logs\'
        }
    Start-Process  -FilePath powershell.exe -ArgumentList "-noexit -command `"Get-Content '$Logpath\$log.log' -Last 20 -wait`""
    }

<#
Start-Process  -FilePath powershell.exe -ArgumentList "Get-Content 'C:\Program Files\EMC NetWorker\nsr\applogs\nsrnmmsv.log' 
Start-Process  -FilePath powershell.exe -ArgumentList "Get-Content 'C:\Program Files\EMC NetWorker\nsr\applogs\nsrnmmra.log' -Last 20 -wait"
Start-Process  -FilePath powershell.exe -ArgumentList "Get-Content 'C:\Program Files\EMC NetWorker\nsr\logs\daemon.log' -Last 20 -wait"

$Host.UI.RawUI.WindowTitle = "$Computername"
do {Get-EventLog -LogName Application -Newest 20 -ComputerName $Computername -Source VSS,Networker,Nmm | Sort-Object Time -Descending | ft Time, EntryType, Source, Message -AutoSize; sleep 5 ;Clear-Host } 
until ($false)
#>
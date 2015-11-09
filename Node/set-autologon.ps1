 <#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 3
[cmdletBinding()] 
Param( 
[Parameter(Mandatory=$false)][string]$domain = $Env:USERDOMAIN,
[Parameter(Mandatory=$false)][string]$user,
[Parameter(Mandatory=$false)][string]$Password = "Password123!" 
)
$WinLogonPath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $WinLogonPath "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty $WinLogonPath "DefaultUsername" -Value "$Env:USERDOMAIN\$User" -type String
Set-ItemProperty $WinLogonPath "DefaultPassword" -Value "$Password" -type String
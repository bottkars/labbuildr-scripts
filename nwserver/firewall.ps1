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
    [Parameter(mandatory = $true)]$BackupAdmin,
    [Parameter(mandatory = $true)]$Hostprefix,
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $Prereq ="Prereq"
     
)
$Nodescriptdir = "$Scriptdir\Node"
$NWScriptDir = "$Scriptdir\nwserver"
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
############
Set-Content -Path $Logfile "$nodeIP, $subnet, $nodename"

Write-Host "Opening firewall on Public for Networker Management Console" 
New-NetFirewallRule -DisplayName "Networker Server RPC 9001" -Direction Inbound -Protocol TCP -LocalPort 9001 -Profile Public -Enabled True
New-NetFirewallRule -DisplayName "Networker Server 9000" -Direction Inbound -Protocol TCP -LocalPort 9000 -Profile Public -Enabled True
New-NetFirewallRule -DisplayName "Networker Server DBquery" -Direction Inbound -Protocol TCP -LocalPort 2638 -Profile Public -Enabled True
New-NetFirewallRule -DisplayName "Networker Management" -Direction Inbound -Protocol TCP -LocalPort 53000-53999 -Profile Public -Enabled True

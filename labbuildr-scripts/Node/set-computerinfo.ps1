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
param(
$Scriptdir = '\\vmware-host\Shared Folders\Scripts',
$SourcePath = '\\vmware-host\Shared Folders\Sources',
$logpath = "c:\Scripts"
)
$Nodescriptdir = Join-Path $Scriptdir "Node"
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
$nodename = $env:COMPUTERNAME
if ((Get-WmiObject -Class Win32_ComputerSystem).Manufacturer -match "VMware")    
    {
    Write-Verbose $Nodescriptdir
    $Computerinfo = ."$Nodescriptdir\get-vmxcomputerinfo.ps1"
    $Arglist = "Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters -Name 'srvcomment' -Value '$nodename running on $($Computerinfo.Hypervisor)'"
    Start-Process -Verb "RunAs" "$PSHOME\powershell.exe" -ArgumentList $Arglist
    Set-ADComputer -identity $nodename -Description "VMHost: $($Computerinfo.Hypervisor), Builddate: $($Computerinfo.Builddate)"
    }

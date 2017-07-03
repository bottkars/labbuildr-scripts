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
    [Parameter(Mandatory=$false)][string]$computer = ".",
    [Parameter(Mandatory=$True)][string]$group, 
    [Parameter(Mandatory=$false)][string]$domain = $Env:USERDOMAIN,
    [Parameter(Mandatory=$True)][string]$user, 
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $Password = "Password123!"
)
$Nodescriptdir = "$Scriptdir\Node"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
if (!(Test-Path $logpath))
    {
    New-Item -ItemType Directory -Path $logpath -Force
    }
$Logfile = New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log" -ErrorAction SilentlyContinue
############
try
    {
    $de = [ADSI]"WinNT://$computer/$Group,group" 
    Write-Verbose "Calling ADD with $Domain $User"
    $de.psbase.Invoke("Add",([ADSI]"WinNT://$domain/$user").path)
    }
catch
    {
    Write-Warning "$group does not exist"
    }

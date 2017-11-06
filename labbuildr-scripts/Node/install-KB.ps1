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
    $KB,
    $KBFolder = "WindowsUpdate",
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts"
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
$Logfile = New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log"
Set-Content -Path $Logfile $MyInvocation.BoundParameters
############

$KBPath = Join-Path $SourcePath $KBFolder
Write-Host "==> checking hostfix $KB installled"
$Hotfix_OK = Get-HotFix $KB -ErrorAction SilentlyContinue

if ($Hotfix_OK)
    {
    Write-Host "Hotfix KB already installed"
    }
else
    {
    Write-Host "==> Need to install Hotfix $KB"
    Write-Host "==> looking $KB in $KBPath" 
    try
	    {
    `	$KBFILE = Get-ChildItem -Path $KBPath -Filter "*$KB*.msu"
	    }
    catch
	    {
	    Write-error "Could not get KB File"
	    break
	    }

    if ($KBFILE)
       {
       Write-Host "==> Found $($KBFILE.Fullname), installing may take a while"
       [string]$update = $($KBFILE.Fullname)
       Start-Process -FilePath "wusa.exe" -ArgumentList "`"$update`" /quiet /norestart" -Wait -PassThru
       }
    }

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

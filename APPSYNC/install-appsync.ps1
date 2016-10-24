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
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    [ValidateSet(
    '3.0.0','3.0.1','3.0.2.0'#
    )]
    $APPSYNC_VER='3.0.2'
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
.$Nodescriptdir\test-sharedfolders.ps1 -Folder $Sourcepath
############
$Setuppath = "$SourcePath\APPSYNC*\APPSYNC-$($APPSYNC_VER)-win-x64.exe"
Write-Warning "Installing APPSYNC $APPSYNC_VER, this could take up to 10 Minutes"
.$Nodescriptdir\test-setup.ps1 -setup APPSYNC -setuppath $Setuppath
Write-Warning "Installing APPSYNC $APPSYNC_VER"


$Arguments = "-i silent -f `"$Builddir\appsync.properties`"" 
Start-Process -FilePath $Setuppath -ArgumentList $Arguments -PassThru -Wait
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }


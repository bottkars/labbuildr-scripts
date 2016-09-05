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
    [ValidateSet('1_0_1s','1_0_2h','1_1_0','1_0_1l','1_0_1t','1_0_1u')]
    $openssl_ver='1_0_1t',
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
.$Nodescriptdir\test-sharedfolders.ps1 -Folder $Sourcepath
$Setuppath = "\\vmware-host\Shared Folders\Sources\Win64OpenSSL*-$openssl_ver.exe"
.$NodeScriptDir\test-setup -setup OpenSSL -setuppath $Setuppath

Write-Warning "Installing OPENSSL $openssl_ver"
$setuppath = ((Get-ChildItem -Path $setuppath).FullName | Sort-Object -Descending | Select-Object -First 1)
$OpenSSLArgs = '/silent'
Start-Process -FilePath $Setuppath -ArgumentList $OpenSSLArgs -PassThru -Wait
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

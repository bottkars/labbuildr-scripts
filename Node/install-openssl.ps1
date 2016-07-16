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
    [ValidateSet('1_0_1s','1_0_2h')]
    $opensslver='1_0_2h',
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
$Setuppath = "\\vmware-host\Shared Folders\Sources\Win64OpenSSL*-$opensslver.exe"
.$NodeScriptDir\test-setup -setup OpenSSL -setuppath $Setuppath

Write-Warning "Installing OPENSSL $opensslver"
$setuppath = ((Get-ChildItem -Path $setuppath).FullName | Sort-Object -Descending | Select-Object -First 1)
$OpenSSLArgs = '/silent'
Start-Process -FilePath $Setuppath -ArgumentList $OpenSSLArgs -PassThru -Wait
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

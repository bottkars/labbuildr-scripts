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
    $Program = "*honolulu*.msi",
    $ArgumentList,
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
$Setuppath = "$SourcePath\$Program"
$SetupMsi = Get-ChildItem -Path $Setuppath
$SetupMsi = $SetupMsi  | Select-Object -First 1
$Logfile = New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log"
Set-Content -Path $Logfile $MyInvocation.BoundParameters
############
.$Nodescriptdir\test-sharedfolders.ps1 -folder $Sourcepath
.$NodeScriptDir\test-setup -setup $Program -setuppath $Setuppath
# Start-Process -FilePath $Setuppath -ArgumentList $ArgumentList -Wait
Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$Setupmsi`" /qn /L*v c:\scripts\honolululog.txt SME_PORT=8088 SSL_CERTIFICATE_OPTION=generate" -Wait

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

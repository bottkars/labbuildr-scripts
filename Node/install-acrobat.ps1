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
    [String]$Product_Dir= "Acrobat",
    [Parameter(Mandatory = $false)]
    [ValidateSet('en_US','de_DE')][string]$lang = "en_US",
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

#.$Nodescriptdir\test-sharedfolders.ps1 -folder $Sourcepath


$Acrobat_Path = Join-Path $SourcePath $Product_Dir

$Acro_Setup = (Get-ChildItem -path $Acrobat_path -filter acro*$lang.msi -file).FullName
[array]$Acro_PATCH = (Get-ChildItem -path $Acrobat_path -filter acro*.msp -file).FullName

if ($Acro_Setup)
    {
    $argumentList = "/i `"$Acro_Setup`" /qb"
    Write-Host -ForegroundColor Magenta "Starting Acrobat Reader DC Setup"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $argumentList  -Wait -PassThru
    if ($Acro_PATCH)
        {
        $Acro_PATCH = $Acro_PATCH | Sort-Object -Descending
        $argumentList = "/p `"$Acro_PATCH`" /qb"
        Write-Host -ForegroundColor Magenta "Starting Acrobat Reader DC Patch"
        Start-Process -FilePath "msiexec.exe" -ArgumentList $argumentList  -Wait -PassThru
        }
    }
else
    {
    Write-Warning "could not find setup for Acrobat $lang in $Acrobat_Path"
    }



if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

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
[Parameter(ParameterSetName = "1", Mandatory = $true,Position = 1)][ValidateSet('af-ZA ',
    'sq-AL ','ar-DZ ','ar-BH ','ar-EG ','ar-IQ ','ar-JO ','ar-KW ','ar-LB ','ar-LY ','ar-MA ','ar-OM ','ar-QA ','ar-SA ','ar-SY ','ar-TN ','ar-AE ','ar-YE ',
    'hy-AM ','Cy-az-AZ ','Lt-az-AZ ','eu-ES ','be-BY ','bg-BG ','ca-ES ','zh-CN ','zh-HK ','zh-MO ','zh-SG ','zh-TW ','zh-CHS ','zh-CHT ','hr-HR ','cs-CZ ',
    'da-DK ','div-MV ','nl-BE ','nl-NL ',
    'en-AU ','en-BZ ','en-CA ','en-CB ','en-IE ','en-JM ','en-NZ ','en-PH ','en-ZA ','en-TT ','en-GB ','en-US ','en-ZW ','et-EE ',
    'fo-FO ','fa-IR ','fi-FI ','fr-BE ','fr-CA ','fr-FR ','fr-LU ','fr-MC ','fr-CH ','gl-ES ','ka-GE ',
    'de-AT ','de-DE ','de-LI ','de-LU ','de-CH ',
    'el-GR ','gu-IN ','he-IL ','hi-IN ','hu-HU ','is-IS ','id-ID ','it-IT ','it-CH ','ja-JP ','kn-IN ','kk-KZ ','kok-IN ','ko-KR ','ky-KZ ','lv-LV ','lt-LT ','mk-MK ','ms-BN ','ms-MY ','mr-IN ','mn-MN ',
    'nb-NO ','nn-NO ','pl-PL ','pt-BR ','pt-PT ','pa-IN ','ro-RO ','ru-RU ','sa-IN ','Cy-sr-SP ','Lt-sr-SP ','sk-SK ','sl-SI ',
    'es-AR ','es-BO ','es-CL ','es-CO ','es-CR ','es-DO ','es-EC ','es-SV ','es-GT ','es-HN ','es-MX ','es-NI ','es-PA ','es-PY ','es-PE ','es-PR ','es-ES ','es-UY ','es-VE ',
    'sw-KE ','sv-FI ','sv-SE ','syr-SY ','ta-IN ','tt-RU ','te-IN ','th-TH ','tr-TR ','uk-UA ','ur-PK ','Cy-uz-UZ ','Lt-uz-UZ ','vi-VN '
)]$LanguageTag = "en-US",
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
#.$Nodescriptdir\test-sharedfolders.ps1
##### Configure WINRM
Write-Host -ForegroundColor Gray " ==>setting language to $LanguageTag"
$Locale = $LanguageTag -replace "_","-"
Set-Culture $Locale
Set-WinSystemLocale $Locale
Set-WinUserLanguageList -LanguageList $Locale -Force

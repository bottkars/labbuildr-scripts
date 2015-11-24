            
param
    (
    [ValidateSet('de-De','en-Us')]$Locale = 'de-De'
    )
$Builddir = $PSScriptRoot

$Content = get-content "$Builddir\2016TP3_HV.xml"
foreach ($Pattern in ('InputLocale','SystemLocale','UserLocale','UILanguage'))
    {     
    $Content = $Content -replace  "^*<$Pattern>.*$"," <$Pattern>$Locale</$Pattern>"
    $Content = $Content -replace  "^*<UILanguageFallback>.*$","<UILanguageFallback>en-Us</UILanguageFallback>"       
    }
    
$Content | Set-Content -Path "$Builddir\answerfile.xml"
if ((Get-WindowsFeature net-framework-core).installstate -ne "installed")
    {
    Write-Warning "We need to install Net-Framework-Core in order to run SQL Based VM´s"
    $CDRom = (Get-Volume | where DriveType -Match CDROM).DriveLetter
    if (!$CDRom)
        {
        Write-Warning "Please insert Windows INSTALL CD into VM"
        break 
        }
    if (!(Test-Path "$($CDRom):\sources\sxs"))
        {
        Write-Warning "Wrong CD inserted"
        }
    Add-WindowsFeature net-framework-core -Source "$($CDRom):\sources\sxs"
    }

Start-Process "c:\windows\system32\sysprep\sysprep.exe" -ArgumentList "/generalize /oobe /unattend:$Builddir\answerfile.xml"


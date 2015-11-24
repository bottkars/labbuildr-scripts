[CmdletBinding(SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
param
    (
    [ValidateSet('de-De','en-Us')]$Locale = 'de-De'
    )
$Builddir = $PSScriptRoot
write-host "Generating Answerfile with Locale $Locale"
$Content = get-content "$Builddir\2016TP3_HV.xml"
foreach ($Pattern in ('InputLocale','SystemLocale','UserLocale','UILanguage'))
    {     
    $Content = $Content -replace  "^*<$Pattern>.*$"," <$Pattern>$Locale</$Pattern>"
    $Content = $Content -replace  "^*<UILanguageFallback>.*$","<UILanguageFallback>en-Us</UILanguageFallback>"       
    }
new-item -ItemType Directory c:\scripts -force | out-null
$Content | Set-Content -Path "c:\sysprep\answerfile.xml" -Force
write-host "Checking for Net-Framework-Core"
if ((Get-WindowsFeature net-framework-core).installstate -ne "installed")
    {
    Write-Warning "We need to install Net-Framework-Core in order to run SQL Based VM´s"
    $CDRom = (Get-Volume | where DriveType -Match "CD-ROM").DriveLetter
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
Write-Host "Starting Sysprep"
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            Write-Verbose "Press any Key to continue to sysprep"
            pause
            }

Start-Process "c:\windows\system32\sysprep\sysprep.exe" -ArgumentList "/generalize /oobe /unattend:$Builddir\answerfile.xml"


[CmdletBinding(SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
param
    (
    [ValidateSet('de-De','en-Us')]$Locale = 'en-Us',
    #[ValidateSet('Server2012R2','Server2016')]$Version = 'Server2016',
    $Productkey
    )
$Builddir = $PSScriptRoot
$Scriptdir = "c:\scripts"
Write-Host -ForegroundColor Magenta "Checking OS version"
$OS_VER = (Get-ItemProperty -Path c:\windows\system32\hal.dll).VersionInfo.FileVersion
Write-host -ForegroundColor Yellow "Running OS Version $OS_VER"
$OS_Major = ([Environment]::OSVersion.Version).Major
$OS_Build = ([Environment]::OSVersion.Version).Build

Write-Host -ForegroundColor Magenta "Checking Machine Type"
if ((Get-WmiObject -Class Win32_ComputerSystem).Manufacturer -match "VMware")    
    {
    Write-Host "Found VMware Virtual Machine, Checking for VMware Tools Installed"
    $VMware_Tools_Ver = (get-itemproperty 'hklm:\software\microsoft\windows\currentversion\uninstall\*' |where-object{ $_.DisplayName -match "VMware Tools"}).Displayversion
    If (!$VMware_Tools_Ver)
        {
        Write-Warning "Please Install VMware Tools!"
        break
        }
    else
        {
        Write-Host -ForegroundColor Magenta "Found VMware Tools $VMware_Tools_Ver"
        }
    }
    

$DISM_Param1 = "/online /Cleanup-Image /StartComponentCleanup /ResetBase"
$DISM_Param2 = "/online /Cleanup-Image /SPSuperseded"
Switch ($OS_Major)
    {
    6
        {
        switch ($OS_Build)
            {
            9200
                {
                $DISM_Param1 = "/online /Cleanup-Image /StartComponentCleanup"
                $Version = 'Server2012'
                }
            9600
                {
                $Version = 'Server2012R2'
                }
            }
        }
    10
        {
        if ($OS_Build -ge 17000)
            {
                $Version = 'WS_INSIDER'
            } 
        else {
            {
                $Version = 'Server2016'
            }
        }       
        }
    }
Write-Host -ForegroundColor Magenta "==> Starting Image Optimization Phase 1"
Start-Process "c:\windows\system32\Dism.exe" -ArgumentList $DISM_Param1 -Wait
Write-Host -ForegroundColor Magenta "==> Cleaning Image Phase 2"
Start-Process "c:\windows\system32\Dism.exe" -ArgumentList $DISM_Param2 -Wait



write-host "Generating Answerfile with Locale $Locale"
$Content = get-content "$Builddir\$Version.xml"
foreach ($Pattern in ('InputLocale','SystemLocale','UserLocale','UILanguage'))
    {     
    $Content = $Content -replace  "^*<$Pattern>.*$"," <$Pattern>$Locale</$Pattern>"
    $Content = $Content -replace  "^*<UILanguageFallback>.*$","<UILanguageFallback>en-Us</UILanguageFallback>"       
    }
if ($Productkey)
    {
    $Content = $Content -replace  "^*<Key>.*$"," <Key>$Productkey</Key>"
    $Content = $Content -replace  "^*<Productkey>.*$"," <Productkey>$Productkey</Productkey>"
    }

# 2KNJJ-33Y9H-2GXGX-KMQWH-G6H67
if ($VMware_Tools_Ver)
    {
    write-host 
    $Content = $Content | where {$_ -notmatch "commandline"}
    }
new-item -ItemType Directory $Scriptdir -force | out-null
$Content | Set-Content -Path "$Scriptdir\answerfile.xml" -Force
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
Write-Host -ForegroundColor Red "We will start Sysprep for $Version, system will be reset !"
Write-Verbose "Press any Key to continue to sysprep or ctrl-c to stop"
pause

Start-Process "c:\windows\system32\sysprep\sysprep.exe" -ArgumentList "/generalize /oobe /unattend:$Scriptdir\answerfile.xml"

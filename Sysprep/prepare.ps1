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

Switch ($OS_Major)
    {
        6
        {
        $Version = 'Server2012R2'
        }
        10
        {
        $Version = 'Server2016'
        }
    }

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
Write-Host "Starting Sysprep"
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            Write-Host -ForegroundColor Gray $Content
            Write-Verbose "Press any Key to continue to sysprep"
            pause
            }
Start-Process "c:\windows\system32\sysprep\sysprep.exe" -ArgumentList "/generalize /oobe /unattend:$Scriptdir\answerfile.xml"

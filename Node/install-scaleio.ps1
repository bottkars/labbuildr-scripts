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
    [Parameter(Mandatory=$true)]
    [ValidateSet('MDM','TB','SDS','SDC','gateway','LIA')]$role,
    [Parameter(Mandatory=$true)]$Disks,
    [Parameter(Mandatory=$true)]
    [ValidateSet('1.30-426.0','1.31-258.2','1.31-1277.3','1.31-2333.2','1.32-277.0','1.32-402.1','1.32-403.2','1.32-2451.4')][alias('siover')]$ScaleIOVer,
    [Parameter(Mandatory=$false)]$mdmipa,
    [Parameter(Mandatory=$false)]$mdmipb,
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
$ScaleIORoot = Join-Path $SourcePath "Scaleio"
While ((Test-Path $ScaleIORoot) -Ne $true)
    {
    Write-Warning "Cannot find $ScaleIORoot
    Make sure USB Drive Connected to Host
    Make Sure USB Stick IS NOT connected to VM
    press any key when done pr Ctrl-C to exit"
    pause
    }
$ScaleIO_Major = ($ScaleIOVer.Split("-"))[0]
if ($role -eq 'gateway')
    {
    try
        {
        $Setuppath = @()
        $Setuppath += (Get-ChildItem -Path $ScaleIORoot -Recurse -Filter "*$role*-x64.msi" -Exclude ".*" -ErrorAction Stop ).FullName
        Write-Host $Setuppath
        }
    Catch
        {
        Write-Warning "Cannot find ScaleIO $ScaleIOVer in $ScaleIORoot
        Make sure the Windows Package is downloaded and extracted to $ScaleIORoot
        or select different version
        press any key when done pr Ctrl-C to exit"
        Break
        }
    
    $Setuppath = $Setuppath[0]
    $ScaleIOArgs = 'GATEWAY_ADMIN_PASSWORD=Password123! /i "'+$Setuppath+'" /quiet'
    Write-Verbose "ScaleIO Gateway Args = $ScaleIOArgs"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
    $Content = get-content -Path "C:\Program Files\EMC\scaleio\Gateway\webapps\ROOT\WEB-INF\classes\gatewayUser.properties"
    $Content = $Content -notmatch "mdm.ip.addresses="
    $Content += "mdm.ip.addresses=$mdmipa`;$mdmipb"
    $Content | set-content -Path "C:\Program Files\EMC\scaleio\Gateway\webapps\ROOT\WEB-INF\classes\gatewayUser.properties"
    Restart-Service 'EMC ScaleIO Gateway'
    }
else
    {
    While (!($ScaleIOPath = (Get-ChildItem -Path $ScaleIORoot -Recurse -Filter "*$Role-$ScaleIOVer.msi" -Exclude ".*").Directory.FullName))
    {
    Write-Warning "Cannot find ScaleIO $ScaleIOVer in $ScaleIORoot
    Make sure the Windows Package is downloaded and extracted to $ScaleIORoot
    or select different version
    press any key when done pr Ctrl-C to exit"
    }

    if ($role -ne "SDS")
        {
        $Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-$role-$ScaleIOVer.msi"
        .$NodeScriptDir\test-setup.ps1 -setup "Saleio$role$ScaleIOVer" -setuppath $Setuppath
        $ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
        Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
        }
    foreach ($role in("sds","sdc","lia"))
        {
        $Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-$role-$ScaleIOVer.msi"
        .$NodeScriptDir\test-setup -setup "Saleio$role$ScaleIOVer" -setuppath $Setuppath
        $ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
        Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
        }
    ### configure lia
    $Content = @()
    $Content += "lia_token=Password123!"
    $Content += "lia_enable_configure_call_home=0"
    $Content += Get-Content 'C:\Program Files\EMC\scaleio\lia\cfg\conf.txt'| where {$_ -NotMatch "lia_token"}
    $Content | Set-Content -Path 'C:\Program Files\EMC\scaleio\lia\cfg\conf.txt'
    restart-service lia_service

    
    
    ####sdc checkup

    Write-Verbose "Preparing Disks"
    # $Disks = (get-disk).count-1
    Write-Host $Disks
    # Stop-Service ShellHWDetection
    $PrepareDisk = "'C:\Program Files\EMC\scaleio\sds\bin\prepare_disk.exe'" 
    foreach ($Disk in 1..$Disks)
        {
        Write-Output $Disk
        $Drive = "\\?\PhysicalDrive$Disk"
     Write-Output $Drive
    do {
        Write-Output "Testing ScaleIO Device"
        Start-Process -FilePath "C:\Program Files\EMC\scaleio\sds\bin\prepare_disk.exe" -ArgumentList "$Drive" -Wait
        # sleep 5
        }
    until (Test-Path "c:\scaleio_devices\PhysicalDrive$Disk")
    }
}

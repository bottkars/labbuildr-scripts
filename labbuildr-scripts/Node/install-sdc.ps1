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
	<# ScaleIOVersion
	'2.0-10000.2075','2.0-12000.122' 
	'2.0-7536.0','2.0-7120.0','2.0-6035.0','2.0-5014.0',
	'1.32-277.0','1.32-402.1','1.32-403.2','1.32-2451.4','1.32-3455.5','1.32-4503.5',
	'1.31-258.2','1.31-1277.3','1.31-2333.2',
	'1.30-426.0'
	#>
    [Parameter(Mandatory=$true)]
	[ValidateSet(
	'2.0-10000.2075','2.0-12000.122',
	'2.0-7536.0','2.0-7120.0','2.0-6035.0','2.0-5014.0',
	'1.32-277.0','1.32-402.1','1.32-403.2','1.32-2451.4','1.32-3455.5','1.32-4503.5',
	'1.31-258.2','1.31-1277.3','1.31-2333.2',
	'1.30-426.0'
	)]
    [alias('siover')]$ScaleIOVer,    
	[Parameter(Mandatory=$true)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$mdma,
    [Parameter(Mandatory=$false)][ValidateScript({$_ -match [IPAddress]$_ })][ipaddress]$mdmb,
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
$ScaleIORoot = "\\vmware-host\shared folders\Sources\Scaleio\"
While ((Test-Path $ScaleIORoot) -Ne $true)
    {
    Write-Warning "Cannot find $ScaleIORoot
    Make sure USB Drive Connected to Host
    Make Sure USB Stick IS NOT connected to VM
    press any key when done pr Ctrl-C to exit"
    pause
    }
$ScaleIO_Major = ($ScaleIOVer.Split("-"))[0]
While (!($ScaleIOPath = (Get-ChildItem -Path $ScaleIORoot -Recurse -Filter "*mdm-$ScaleIOVer.msi" -Exclude ".*").Directory.FullName))
    {
    Write-Warning "Cannot find ScaleIO $ScaleIOVer in $ScaleIORoot
    Make sure the Windows Package is downloaded and extracted to $ScaleIORoot
    or select different version
    press any key when done pr Ctrl-C to exit"
    pause
    }
$role = "sdc"
$Setuppath = Join-Path $ScaleIOPath "EMC-ScaleIO-$role-$ScaleIOVer.msi"
.$NodeScriptDir\test-setup -setup "Saleio$role$ScaleIOVer" -setuppath $Setuppath
$ScaleIOArgs = '/i "'+$Setuppath+'" /quiet'
Start-Process -FilePath "msiexec.exe" -ArgumentList $ScaleIOArgs -PassThru -Wait
$ScaleIO_Major = ($ScaleIOVer.Split("-"))[0]
if (!$mdmb)
    {
    $mdm_ip = $mdma
    }
else
    {
    $mdm_ip = "$mdma,$mdmb"
    }
."C:\Program Files\emc\scaleio\sdc\bin\drv_cfg.exe" --add_mdm --ip $mdm_ip
."C:\Program Files\emc\scaleio\sdc\bin\drv_cfg.exe" --query_mdms

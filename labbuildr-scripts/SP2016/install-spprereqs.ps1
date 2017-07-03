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
param (
$sp_version= "SP2016",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
[ValidateSet('exe','img')]$install_from = 'img',
$logpath = "c:\Scripts",
$Setupcmd = "PrerequisiteInstaller.exe"
)

$Sharepoint_Dir = Join-Path $Sourcepath "Sharepoint"
$Nodescriptdir = "$Scriptdir\NODE"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log"
.$Nodescriptdir\test-sharedfolders.ps1 -folder $SourcePath

if ($install_from -eq "exe")
    {
    $Setuppath = "$Sharepoint_Dir\$sp_version\$Setupcmd"
    .$Nodescriptdir\test-setup -setup $sp_version -setuppath $Setuppath
    }
else
    {
	switch ($sp_cu)
		{
			default
			{
			$iso = "officeserver.img"
			}
		}
	$Isopath = "$Sharepoint_Dir\$sp_version\$iso"

    Write-Verbose $Isopath
	.$Nodescriptdir\test-sharedfolders.ps1 -folder $Isopath

	if (!(Test-Path $env:USERPROFILE\Downloads\$iso))
		{
		Write-Host -ForegroundColor Gray "Copying Sharepoint ISO locally"
		Copy-Item $Isopath -Destination "$env:USERPROFILE\Downloads"
		}
	else
		{
		Write-Host "No Copy required"
		}
    
    $Temp_Iso = "$env:USERPROFILE\Downloads\$Iso"
    $ismount = Mount-DiskImage -ImagePath $Temp_Iso -PassThru
    $Driveletter = (Get-Volume | where { $_.size -eq $ismount.Size}).driveletter
    $Setuppath = "$($Driveletter):\$Setupcmd"
    }

<#
copy and replace product key
NQGJR-63HC8-XCRQH-MYVCH-3J3QR

#>

$Prereqpath = "$Sourcepath\Sharepoint\$($sp_version)Prereq"

.$Nodescriptdir\\test-setup.ps1 -setup "Sharepoint 2016" -setuppath $Setuppath
<#
/SQLNCli:<file> Install Microsoft SQL Server 2012 SP1 Native Client from <file>.
/IDFX11:<file> Install Windows Identity Foundation v1.1 from <file>.
/Sync:<file> Install Microsoft Sync Framework Runtime SP1 v1.0 (x64) from <file>.
/AppFabric:<file> Install Windows Server AppFabric from <file> (AppFabric must be installed with the options /i CacheClient,CachingService,CacheAdmin /gac).
/KB3092423:<file> Install Cumulative Update Package 7 for Microsoft AppFabric 1.1 for Windows Server (KB3092423) from <file>.
/MSIPCClient:<file> Install Microsoft Information Protection and Control Client from <file>.
/WCFDataServices56:<file> Install Microsoft WCF Data Services 5.6 from <file>.
/ODBC:<file>Install Microsoft ODBC Driver 11 for SQL Server from <file>.
/DotNetFx:<file>Install Microsoft .NET Framework 4.6 from <file>.
/MSVCRT11:<file> Install Visual C++ Redistributable Package for Visual Studio 2012 from <file>.
/MSVCRT14:<file> Install Visual C++ Redistributable Package for Visual Studio 2015 from <file>.
#>
$arguments = "/SQLNCli:`"$Prereqpath\sqlncli.msi`" /IDFX11:`"$Prereqpath\MicrosoftIdentityExtensions-64.msi`" /Sync:`"$Prereqpath\Synchronization.msi`" /AppFabric:`"$Prereqpath\WindowsServerAppFabricSetup_x64.exe`" /KB3092423:`"$Prereqpath\AppFabric-KB3092423-x64-ENU.exe`" /MSIPCClient:`"$Prereqpath\setup_msipc_x64.exe`" /WCFDataServices56:`"$Prereqpath\WcfDataServices.exe`" /ODBC:`"$Prereqpath\msodbcsql.msi`" /DotNetFx:`"$Prereqpath\NDP46-KB3045557-x86-x64-AllOS-ENU.exe`" /MSVCRT11:`"$Prereqpath\vc_redist.x64.exe`" /MSVCRT14:`"$Prereqpath\vcredist_x64.exe`"" #>
Write-Verbose "Trying Prereq Install"

Write-Host "running 
$Setuppath /unattended $arguments
"

Start-Process $Setuppath -ArgumentList "/unattended $arguments" -Wait

if ($Temp_Iso)
	{
	Dismount-DiskImage -ImagePath $Temp_Iso -PassThru
	}
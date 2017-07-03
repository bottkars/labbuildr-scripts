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
$Setupcmd = "Setup.exe",
[Validateset('AAG','MSDE')]$DBtype,
$DBInstance
)
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$Builddir\$ScriptName$Logtime.log"

$Sharepoint_Dir = Join-Path $Sourcepath "Sharepoint"
$Setuppath = "$SourcePath\$sp_version\$Setupcmd"
$Nodescriptdir = Join-Path $Scriptdir "Node"
.$Nodescriptdir\test-sharedfolders.ps1



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
    Write-Verbose $Driveletter
    $Setuppath = "$($Driveletter):\$Setupcmd"
    }
switch ($DBtype)
    {
    'AAG'
    {
    $arguments = "/config `"$Scriptdir\SP2016\config.xml`""
    }
    'MSDE'
    {
    }
    default
    {
    $arguments = "/config `"$Scriptdir\SP2016\config.xml`""
    }

    }
Write-Warning "Installing Sharepoint may take up to 25 Minutes"
.$Nodescriptdir\test-setup -setup $sp_version -setuppath $Setuppath

if ($DBtype -eq 'MSDE')
	{
	Start-Process $Setuppath -Wait

	}
else
	{
	Start-Process $Setuppath -ArgumentList $arguments -Wait

	}

if ($Temp_Iso)
	{
	Dismount-DiskImage -ImagePath $Temp_Iso -PassThru
	}
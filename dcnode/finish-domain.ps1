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
$Domain,
$domainsuffix = "local",
$logpath = "c:\Scripts"
)
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
$MyDomain = "$($Domain).$($Domainsuffix)"
Write-Verbose "trying tools update"
try {
    $CDDrive = Get-Volume -FileSystemLabel "VMware Tools"  -ErrorAction SilentlyContinue
    }
catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]
    {
    
    }

if ($CDDrive)
    {
    Write-Warning "Starting Tools Update from $($CDDrive.DriveLetter)" 
    Start-Process "$($CDDrive.DriveLetter):\setup.exe" -ArgumentList "/S /v `"/qn REBOOT=R ADDLOCAL=ALL" -Wait
    }

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Install-ADDSForest -DomainName $MyDomain -SkipPreChecks -safemodeadministratorpassword (convertto-securestring "Password123!" -asplaintext -force) -DomainMode Win2012 -DomainNetbiosname $Domain -ForestMode Win2012 -InstallDNS -NoRebootOnCompletion -Force
	New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "Pass3" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path $logpath\3.pass`""
	Pause
    Restart-Computer
    }
else
    {
    Install-ADDSForest -DomainName $MyDomain -SkipPreChecks -safemodeadministratorpassword (convertto-securestring "Password123!" -asplaintext -force) -DomainMode Win2012 -DomainNetbiosname $Domain -ForestMode Win2012 -InstallDNS -NoRebootOnCompletion -Force
	New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "Pass3" -Value "$PSHOME\powershell.exe -Command `"New-Item -ItemType File -Path $logpath\3.pass`""
	Restart-Computer
	}

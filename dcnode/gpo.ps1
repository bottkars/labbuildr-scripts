[CmdletBinding()]
param (
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
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


function Extract-Zip
{
	
    param([string]$zipfilename, [string] $destination)
    $copyFlag = 16 # overwrite = yes 
    $Origin = $MyInvocation.MyCommand
	if(test-path($zipfilename))
	{	
		$shellApplication = new-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipfilename)
		$destinationFolder = $shellApplication.NameSpace($destination)
		$destinationFolder.CopyHere($zipPackage.Items(),$copyFlag)
	}
}
Extract-Zip "$Scriptdir\dcnode\gpo.zip" c:\
Import-GPO -BackupGpoName "Default Domain Policy" -TargetName "Default Domain Policy" -Path C:\GPO

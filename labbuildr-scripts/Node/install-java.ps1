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
    [Parameter(ParameterSetName = "1", Mandatory = $true)]
    [ValidateSet(
    '7','8'
    )][string]$java_Ver,
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts",
    $prereq = 'prereq'
)
$Nodescriptdir = "$Scriptdir\Node"
$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
if (!(Test-Path $logpath))
    {
    New-Item -ItemType Directory -Path $logpath -Force
    }
$Logfile = New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log"
Set-Content -Path $Logfile $MyInvocation.BoundParameters
############
.$Nodescriptdir\test-sharedfolders.ps1 -folder $Sourcepath

switch ($java_ver)
{
    '7'
    {
    Write-Verbose "Checking for Java 7"
    if (!($Java7 = Get-ChildItem -Path $SourcePath -Filter 'jre-7*x64*.exe'))
	    {
		Write-Host -ForegroundColor Yellow " ==> Java7 not found, please download from labbuildr repo"
        break
        }
    $Java7 = Get-ChildItem -Path $SourcePath -Filter 'jre-7*x64*.exe'	    
    $Java7 = $Java7 | Sort-Object -Property Name -Descending
    $SetupCMD = $Java7[0].Name
        $ArgumentList = '/s SPONSORS=DISABLE WEB_JAVA_SECURITY_LEVEL=M'
    }

    '8'
    {
    Write-Verbose "Checking for Java 8"
    if (!($Java8 = Get-ChildItem -Path $Sourcepath -Filter 'jre-8*x64*.exe'))
        {
	    Write-Host -ForegroundColor Gray " ==> Java8 not found, please use receive-labjava64"
        break
        }
    else
        {
        $Java8 = $Java8 | Sort-Object -Property Name -Descending
	    $SetupCMD = $Java8[0].Name
        Write-Verbose "Got $SetupCMD"
        $ArgumentList = 'INSTALL_SILENT=1 REBOOT=0 AUTO_UPDATE=0 SPONSORS=0 WEB_JAVA_SECURITY_LEVEL=M'
        }
    }

}

$Setuppath = "$SourcePath\$Setupcmd"
.$NodeScriptDir\test-setup.ps1 -setup $Setupcmd -setuppath $SetupPath
Write-Host -ForegroundColor Magenta " ==> installing Java $java_Ver from $SetupCMD"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
Start-Process $Setuppath -ArgumentList $ArgumentList -PassThru -Wait

switch ($java_ver)
{
    '7'
    {
    } 
    '8'
    {
    Write-Host "Setting Java Path"    
    [Environment]::SetEnvironmentVariable("JAVA_HOME",(Get-ItemProperty 'HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment\1.8' -PSProperty JavaHome).JavaHome, "User")
    [Environment]::SetEnvironmentVariable("JRE_HOME",(Get-ItemProperty 'HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment\1.8' -PSProperty JavaHome).JavaHome, "User")        
    }     
}    

param(
$Scriptdir = '\\vmware-host\Shared Folders\Scripts',
$SourcePath = '\\vmware-host\Shared Folders\Sources',
$logpath = "c:\Scripts"
)
$Nodescriptdir = Join-Path $Scriptdir "Node"
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
$SeService = "SeServiceLogonRight = *"
$SID = (get-aduser nmmbackupuser).SID.Value
$AddSecurity = @('[Unicode]','Unicode=yes','[Version]','signature="$CHICAGO$"','Revision =1','[Privilege Rights]',"$SeService$Sid")
$AddSecurity |  Add-Content -path c:\scripts\security.inf
secedit.exe /import /db secedit.sdb /cfg "C:\scripts\security.inf"
gpupdate.exe /force

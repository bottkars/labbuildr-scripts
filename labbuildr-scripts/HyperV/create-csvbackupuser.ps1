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
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$logpath = "c:\Scripts",
[parameter(mandatory = $false)]$PlainPassword = "Password123!",
[parameter(mandatory = $false)]$BackupAdmin = "HyperVBackupUser"
)
$Nodescriptdir = "$Scriptdir\NODE"
$EXScriptDir = "$Scriptdir\$ex_version"
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
######################################################################
Function Add-DomainUserToLocalGroup 
{ 
[cmdletBinding()] 
Param( 
[Parameter(Mandatory=$True)][string]$computer, 
[Parameter(Mandatory=$True)][string]$group, 
[Parameter(Mandatory=$True)][string]$domain, 
[Parameter(Mandatory=$True)][string]$user 
) 
$de = [ADSI]"WinNT://$computer/$Group,group"

try
    { 
    $de.psbase.Invoke("Add",([ADSI]"WinNT://$domain/$user").path)
    }
catch
    {
    Write-Warning "Adding $user to $group on $computer : $_"
    }     
} #end function Add-DomainUserToLocalGroup
$ADDomain = (get-addomain).forest
$maildom= "@"+$ADDomain

#$PlainPassword = "Password123!"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
try
    {
    New-ADUser -Name $BackupAdmin -AccountPassword $SecurePassword -PasswordNeverExpires $True -Enabled $True -EmailAddress "$BackupAdmin$maildom" -samaccountname $BackupAdmin -userprincipalname "$BackupAdmin$Maildom"  -ErrorAction SilentlyContinue
    }
catch
    {
    Write-Warning "Create  $BackupAdmin : $_ "
    }
foreach ($ADgroup in ( "Remote Desktop Users"))#, "Windows Authorization Access Group"))
    {
    Write-Verbose "Adding $BackupAdmin to $ADgroup"
    Add-ADGroupMember -Identity $ADgroup -Members $BackupAdmin
    }
Write-Verbose "Granting ClusterAccess for $BackupAdmin"
Grant-ClusterAccess -User $ADDomain\$BackupAdmin -Full

$Nodes = get-cluster . | Get-ClusterNode
foreach ($Node in $Nodes)
    {
    foreach ($localgroup in ( "Administrators", "Backup Operators", "Hyper-V Administrators","Remote Desktop Users"))
        {
        Write-verbose "Adding $BackupAdmin to $localgroup on $Node"
        Add-DomainUserToLocalGroup -computer $Node.Name -group $localgroup -domain $ADDomain -user $BackupAdmin
        }
    }

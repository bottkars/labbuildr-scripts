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
param (
$DAGIP = "192.168.2.120",
[ValidateSet('IPv4','IPv6','IPv4IPv6')][string]$AddressFamily = 'IPv4',
 $ex_version= "E2010",
$ExDatabasesBase = "C:\ExchangeDatabases",
$ExVolumesBase = "C:\ExchangeVolumes",
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$logpath = "c:\Scripts"
)
$Nodescriptdir = "$Scriptdir\NODE"

$ScriptName = $MyInvocation.MyCommand.Name
$Host.UI.RawUI.WindowTitle = "$ScriptName"
$Builddir = $PSScriptRoot
$Logtime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
New-Item -ItemType file  "$logpath\$ScriptName$Logtime.log"
############
Write-Verbose $AddressFamily
Write-Verbose $DAGIP
Write-Verbose "Please check dagparm"
Write-Output $PSCmdlet.MyInvocation.BoundParameters
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
$Domain = $env:USERDOMAIN
$Dagname = $Domain+"DAG"
$WitnessDirectory = "C:\FSW_"+$Dagname
$DB = "DB2"
$PlainPassword = "Password123!"
$DomainUser = "$Domain\Administrator"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $DomainUser, $SecurePassword
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$env:COMPUTERNAME/PowerShell/ -Authentication Kerberos -Credential $Credential
Import-PSSession $Session

$WitnessServer = (Get-DomainController).name
$ADAdminGroup = Get-ADGroup -Filter * | where name -in ('Administrators','Administratoren')
$ADTrustedEXGroup = Get-ADGroup -Filter * | where name -eq "Exchange Trusted Subsystem"
Add-ADGroupMember -Identity $ADAdminGroup -Members $ADTrustedEXGroup  -Credential $Credential

Write-Host "Creating the DAG" -foregroundColor Yellow

New-DatabaseAvailabilityGroup -name $DAGName -WitnessServer $WitnessServer -WitnessDirectory $WitnessDirectory -DatabaseAvailabilityGroupIPAddress $DAGIP
#Set-DatabaseAvailabilityGroup $Dagname -AutoDagDatabasesRootFolderPath $ExDatabasesBase
#Set-DatabaseAvailabilityGroup $Dagname -AutoDagVolumesRootFolderPath $ExVolumesBase
#Set-DatabaseAvailabilityGroup $Dagname -AutoDagVolumesRootFolderPath $ExVolumesBase
#Set-DatabaseAvailabilityGroup $Dagname -AutoDagDatabaseCopiesPerVolume 1
Write-Host "Adding DAG Member" $Server -ForeGroundColor Yellow

$MailboxServers = Get-MailboxServer "$($EX_Version)*"| Select -expandProperty Name
foreach($Server in $MailboxServers){
    Add-DatabaseAvailabilityGroupServer -id $DAGName -MailboxServer $Server
}
write-host "DAG $Dagname created"
if ($DAGIP -ne ([System.Net.IPAddress])::None) { 
write-host "Changing PTR Record" 
########## changing cluster to register PTR record 
$res = Get-ClusterResource "Cluster Name" 
Set-ClusterParameter -Name PublishPTRRecords -Value 1 -InputObject $res
Stop-ClusterResource -Name $res
Start-ClusterResource -Name $res
}




################# Create database

Write-Host "Creating Mailbox Database $DB " -foregroundcolor yellow
New-MailboxDatabase -Name $DB -EDBFilePath "$ExDatabasesBase\$DB\$DB.DB\$DB.EDB" -LogFolderPath "$ExDatabasesBase\$DB\$DB.Log" -Server $env:COMPUTERNAME
Mount-Database -id $DB
Write-Host "Setting Offline Address Book" -foregroundcolor Yellow
Set-MailboxDatabase $DB -offlineAddressBook "Default Offline Address Book"

############### create copies
	
foreach($Server in $MailboxServers){
		if(!($Server -eq $ENV:ComputerName)){
		Write-Host "Creating database Copy $DB" -foregroundcolor yellow
			Add-MailboxDatabaseCopy -id $DB -MailboxServer $Server
		}
	}


Remove-PSSession $Session
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

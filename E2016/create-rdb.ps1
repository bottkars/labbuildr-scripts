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
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$logpath = "c:\Scripts",
$ex_version= "E2016",
$Prereq ="Prereq" 
)
$Nodescriptdir = "$Scriptdir\NODE"
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
$BackupAdmin = "NMMBackupUser"
$Dot = "."
$Domain = $Env:USERDOMAIN
$PlainPassword = "Password123!"
$DomainUser = "$Domain\Administrator"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $DomainUser, $SecurePassword
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$env:COMPUTERNAME/PowerShell/ -Authentication Kerberos -Credential $Credential
Import-PSSession $Session
$ADDomain = (get-addomain).forest
$Smtpserver = $env:COMPUTERNAME+"."+$env:USERDNSDOMAIN
New-Item -ItemType Directory -Path r:\rdb
New-Item -ItemType Directory -Path s:\rdb
New-MailboxDatabase -Recovery -Name rdb$env:COMPUTERNAME -server $Smtpserver -EdbFilePath R:\rdb\rdb.edb  -logFolderPath S:\rdb
get-ExchangeServer  | add-adpermission -user $BackupAdmin -accessrights ExtendedRight -extendedrights Send-As, Receive-As, ms-Exch-Store-Admin
Remove-PSSession $Session

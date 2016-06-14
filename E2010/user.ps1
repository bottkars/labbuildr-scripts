<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
#requires -version 2
[CmdletBinding()]
param(
$Subnet = "192.168.2",
[ValidateSet('IPv4','IPv6','IPv4IPv6')][string]$AddressFamily = 'IPv4',
$IPV6Prefix,
$Scriptdir = "\\vmware-host\Shared Folders\Scripts",
$SourcePath = "\\vmware-host\Shared Folders\Sources",
$logpath = "c:\Scripts",
$ex_version= "E2010",
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
$Dot = "."
$Domain = $env:USERDOMAIN
$ADDomain = $env:USERDNSDOMAIN
$maildom= "@"+$ADDomain
$Space = " "
$Database = "DB1_"+$env:COMPUTERNAME
$Subject = "Welcome to $Domain"
$SenderSMTP = "Administrator"+$maildom
$Smtpserver = $env:COMPUTERNAME+$Dot+$ADDomain
$BackupAdmin = "NMMBackupUser"
$Body = "Welcome to Exchange at $Domain
Enjoy the new Features
Try Networker and/or Avamar with the new Environment !
... for Questions drop an email to Karsten.Bott@emc.com
Follow me on twitter @sddc_Guy
Make sure to Star my Wiki !
https://github.com/bottkars/labbuildr/wiki"
$AttachDir =  "$SourcePath\Attachments"
$PlainPassword = "Password123!"
$DomainUser = "$Domain\Administrator"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $DomainUser, $SecurePassword
Set-TransportConfig -MaxReceiveSize 50MB
Set-TransportConfig -MaxSendSize 50MB
Enable-Mailbox -Identity $BackupAdmin
if (Test-Path $AttachDir)
    {
    [array]$Attachment = Get-ChildItem -Path $AttachDir -Recurse -Filter *.pdf
    }
$RoleGroup = "EMC NMM Exchange Admin Roles"
$Roles = ("Database Copies", "Databases", "Disaster Recovery", "Mailbox Import Export", "Mail Recipient Creation", "Mail Recipients", "View-Only Configuration", "View-Only Recipients")
New-RoleGroup -Name $RoleGroup -DisplayName $RoleGroup -Members $BackupAdmin -Roles $Roles -Description "This role group allows its users to perform database recovery and GLR"
Add-RoleGroupMember "Discovery Management" –Member $BackupAdmin
Get-MailboxDatabase | Set-MailboxDatabase -CircularLoggingEnabled $false
#### rdb stuff
<#
New-Item -ItemType Directory -Path R:\rdb
New-Item -ItemType Directory -Path S:\rdb
New-MailboxDatabase -Recovery -Name rdb$env:COMPUTERNAME -server $Smtpserver -EdbFilePath R:\rdb\rdb.edb  -logFolderPath S:\rdb
Restart-Service MSExchangeIS
#>
Get-AddressList  | Update-AddressList
Send-MailMessage -From $SenderSMTP -Subject $Subject -To "$BackupAdmin$maildom"  -Body $Body -Attachments $attachment[0].FullName -DeliveryNotificationOption None -SmtpServer $Smtpserver -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
Send-MailMessage -From $SenderSMTP -Subject $Subject -To $SenderSMTP -Body $Body -Attachments $attachment[0].FullName -DeliveryNotificationOption None -SmtpServer $Smtpserver -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
get-ExchangeServer  | add-adpermission -user $BackupAdmin -accessrights ExtendedRight -extendedrights Send-As, Receive-As, ms-Exch-Store-Admin
if (Get-DatabaseAvailabilityGroup)
    {
    $DAGDatabase = Get-MailboxDatabase | where ReplicationType -eq Remote
    $Database = $DAGDatabase.Name
    }
$Users = Import-CSV "$Scriptdir\$ex_version\user.csv" 
if (Test-Path "$SourcePath\customuser*.csv")
    {
    $Users += Import-CSV "$SourcePath\customuser*.csv"
    }
$Users | ForEach {
$givenname=$_.givenname
$surname=$_.surname
$Displayname = $givenname+$Space+$surname
$SamAccountName = $Givenname.Substring(0,1)+$surname
$UPN = $SamAccountName+$maildom
$emailaddress = "$givenname$Dot$surname$maildom"
$name = "$givenname $surname"
$accountpassword=(ConvertTo-SecureString "Welcome1" -AsPlainText -Force)

        New-Mailbox -Name $Displayname -Alias $SamAccountName -UserPrincipalName $UPN -SamAccountName $SamAccountName -FirstName $givenname -Initials '' -LastName $surname -Password $accountpassword -ResetPasswordOnNextLogon $false
        Send-MailMessage -From $SenderSMTP -Subject $Subject -Attachments $attachment[0].FullName -To $UPN -Body $Body -DeliveryNotificationOption None -SmtpServer $Smtpserver -Credential $Credential -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    }
<#
ipmo dnsserver
Write-Host -ForegroundColor Yellow "Setting Up C-record for mailhost"
If ($AddressFamily -match 'IPv4')
    {
    $dnsserver = (Get-DnsClientServerAddress -AddressFamily  IPv4 | where ServerAddresses -match $Subnet).ServerAddresses[0]
    $zone = get-dnsserverzone (Get-ADDomain).dnsroot -ComputerName $dnsserver
    Add-DnsServerResourceRecordCName -HostNameAlias "$env:COMPUTERNAME.$ADDomain" -Name mailhost -ZoneName $zone.ZoneName -ComputerName $dnsserver

    }
If ($AddressFamily -match 'IPv6')
    { 
    $dnsserver = (Get-DnsClientServerAddress -AddressFamily  IPv6 | where ServerAddresses -match $IPv6Prefix).ServerAddresses[0]
    $zone = get-dnsserverzone (Get-ADDomain).dnsroot -ComputerName $dnsserver
    Add-DnsServerResourceRecordCName -HostNameAlias "$env:COMPUTERNAME.$ADDomain" -Name mailhost -ZoneName $zone.ZoneName -ComputerName $dnsserver
    }
#>
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
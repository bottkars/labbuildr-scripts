<#
.Synopsis
   labbuildr allows you to create Virtual Machines with VMware Workstation froim Predefined Scenarios.
   Scenarios include Exchange 2013, SQL, Hyper-V, SCVMM
.DESCRIPTION
   labbuildr builds your on-demand labs
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>
#requires -version 3
[CmdletBinding()]
param (
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
$lclanguage = (Get-WmiObject Win32_OperatingSystem).oslanguage
        switch ($lclanguage) `
        {
            1031 
            {
            $csv_file = "adminuser_ger.csv"
            }
            default 
            {
            $csv_file = "adminuser.csv"
            }
        }
$dnsroot = '@' + (Get-ADDomain).DNSRoot
$accountPassword = (ConvertTo-SecureString "Password123!" -AsPlainText -force)
Import-Csv $Builddir\$csv_file| foreach-object {
   
    if ($_.OU -ne "") { $OU = "OU=" + $_.OU + ',' + (Get-ADDomain).DistinguishedName }
    if (!(Get-ADOrganizationalUnit -Filter * | where name -match $_.OU -ErrorAction SilentlyContinue )){New-ADOrganizationalUnit -Name $_.OU; Write-Host $OU }

    else { $OU = (Get-ADDomain).UsersContainer }
 
    #In case of for example a service account without first and last name.
    if ($_.FirstName -eq"" -and $_.LastName -eq "") { $Name = $_.SamAccountName }
    else { $Name = ($_.FirstName + " " + $_.LastName) }

    
    if ($_.Manager -eq "") 
        {
        try
            {
            $newUser = New-ADUser -Name $Name -SamAccountName $_.SamAccountName -DisplayName $Name -Description $_.Description -GivenName $_.FirstName -Surname $_.LastName `
            -EmailAddress ($_.SamAccountName + $dnsroot) -Title $_.Title `
            -UserPrincipalName ($_.SamAccountName + $dnsroot) -Path $OU -Enabled $true `
            -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
            -AccountPassword $accountPassword -PassThru -ErrorAction SilentlyContinue
            }
        catch
            {
            Write-Warning "$newuser already exists"
            }
        }
    else 
        {
        try
            {
            $newUser = New-ADUser -Name $Name -SamAccountName $_.SamAccountName -DisplayName $Name -Description $_.Description -GivenName $_.FirstName -Surname $_.LastName `
            -EmailAddress ($_.SamAccountName + $dnsroot) -Title $_.Title`
            -UserPrincipalName ($_.SamAccountName + $dnsroot) -Path $OU -Enabled $true `
            -ChangePasswordAtLogon $false -Manager $_.Manager -PasswordNeverExpires $true `
            -AccountPassword $accountPassword -PassThru -ErrorAction SilentlyContinue
             }
        catch
            {
            Write-Warning "$newuser already exists"
            }
        
        }

    if ($_.SecurityGroup -ne "")
        {
        if (!($SecurityGroup = Get-ADGroup -filter * | where name -match $_.SecurityGroup -ErrorAction SilentlyContinue))
            { 
            $SecurityGroup = New-ADGroup -Name $_.SecurityGroup -GroupScope Global -GroupCategory Security -ErrorAction SilentlyContinue
            }
    try
        {
        Add-ADGroupMember -Identity $_.SecurityGroup -Members $newUser -ErrorAction SilentlyContinue
        }
    catch
        {
        Write-Warning "$newuser already in Group"
        }
    }
        
 

}

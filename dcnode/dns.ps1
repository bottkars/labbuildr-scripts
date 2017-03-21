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
$logpath = "c:\Scripts",
$IPV6Prefix = 'fd2d:3c46:82b2::',
$IPv4Subnet = "192.168.2",
[Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily,
[ValidateSet('24')]$IPv4PrefixLength = '24',
[ValidateSet('8','24','32','48','64')]$IPv6PrefixLength = '8',
$DefaultGateway
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
Set-Content -Path $Logfile $PSCmdlet.MyInvocation.BoundParameters
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Output $PSCmdlet.MyInvocation.BoundParameters
    }
Write-Verbose $IPv6PrefixLength
Write-Verbose $IPV6Prefix
$zone = Get-DnsServerzone $env:USERDNSDOMAIN
Write-Host -ForegroundColor Yellow "Generating Reverse Lookup Zone"
if ( $AddressFamily -match 'IPv4')
    {
    $reverse = $IPv4subnet+'.0/'+$IPv4PrefixLength
    Add-DnsServerPrimaryZone -NetworkID $reverse -ReplicationScope "Forest" -DynamicUpdate NonsecureAndSecure
    Add-DnsServerForwarder -IPAddress 8.8.8.8
    if ($DefaultGateway)
        {
        Add-DnsServerForwarder -IPAddress $DefaultGateway
        }
    Write-Verbose "Setting Ressource Records for EMC VA´s"
    Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name vipr1 -IPv4Address "$IPv4Subnet.9" -ZoneName $zone.Zonename
    #Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name nvenode1 -IPv4Address "$IPv4Subnet.12" -ZoneName $zone.Zonename
	#nvenode1 moved to 22
    Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name coprhd_release -IPv4Address "$IPv4Subnet.14" -ZoneName $zone.Zonename
    Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name puppetmaster1 -IPv4Address "$IPv4Subnet.15" -ZoneName $zone.Zonename
    Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name pupetenmaster1 -IPv4Address "$IPv4Subnet.16" -ZoneName $zone.Zonename
    Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name ddmcnode1 -IPv4Address "$IPv4Subnet.20" -ZoneName $zone.Zonename
    Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name geonas_primary -IPv4Address "$IPv4Subnet.70" -ZoneName $zone.Zonename
    foreach ( $N in 1..5)
        {
		$N5 = $N+5
        $N2 = $n+2
		$N4 = $n+4
		if ( $n -le 2)
			{
			Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "ddvenode$N" -IPv4Address "$IPv4Subnet.2$N" -ZoneName $zone.Zonename
			Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "nvenode$N" -IPv4Address "$IPv4Subnet.2$N2" -ZoneName $zone.Zonename
			Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "avenode$N" -IPv4Address "$IPv4Subnet.3$N" -ZoneName $zone.Zonename
			Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "cloudboost$N" -IPv4Address "$IPv4Subnet.7$N" -ZoneName $zone.Zonename
			}
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "coreos$N" -IPv4Address "$IPv4Subnet.4$N" -ZoneName $zone.Zonename
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "cloudarray$N" -IPv4Address "$IPv4Subnet.10$N" -ZoneName $zone.Zonename
        Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "scaleionode$N" -IPv4Address "$IPv4Subnet.19$N" -ZoneName $zone.Zonename
		Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "ubuntu$N" -IPv4Address "$IPv4Subnet.20$n" -ZoneName $zone.Zonename
        if ($N5 -le 8)
			{
			Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "geonas_cache$N" -IPv4Address "$IPv4Subnet.7$N5" -ZoneName $zone.Zonename
			Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "mesosnode$N" -IPv4Address "$IPv4Subnet.22$N5" -ZoneName $zone.Zonename
			Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "ecsnode$N" -IPv4Address "$IPv4Subnet.24$N5" -ZoneName $zone.Zonename
			Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "*.ecsnode$N" -IPv4Address "$IPv4Subnet.24$N5" -ZoneName $zone.Zonename
			}
        if ($N5 -le 9)
			{
			Add-DnsServerResourceRecordA -AllowUpdateAny -CreatePtr -Name "centosnode$N" -IPv4Address "$IPv4Subnet.20$N5" -ZoneName $zone.Zonename
			}

        }
    }
if ( $AddressFamily -match 'IPv6')
    {
    $reverse = $IPV6Prefix+'/'+$IPv6PrefixLength
    }

# Add-DnsServerPrimaryZone "$reverse.in-addr.arpa" -ZoneFile "$reverse.in-addr.arpa.dns" -DynamicUpdate NonsecureAndSecure

Add-DnsServerZoneDelegation -Name $zone.ZoneName -ChildZoneName OneFS -NameServer "smartconnect.$env:USERDNSDOMAIN" -IPAddress "$IPv4Subnet.40"
Add-DnsServerZoneDelegation -Name $zone.ZoneName -ChildZoneName OneFSremote -NameServer "smartconnectremote.$env:USERDNSDOMAIN" -IPAddress "$IPv4Subnet.60"
$reversezone =  Get-DnsServerZone | where { $_.IsDsIntegrated -and $_.IsReverseLookupZone}
$reversezone | Add-DnsServerResourceRecordPtr -AllowUpdateAny -Name "40" -PtrDomainName "smartconnect.$env:USERDNSDOMAIN"
$reversezone | Add-DnsServerResourceRecordPtr -AllowUpdateAny -Name "60" -PtrDomainName "smartconnectremote.$env:USERDNSDOMAIN"
## add some hosts vor avamar and ddve  and others. . .

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }
<#
.Synopsis
   Short description
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://github.com/bottkars/labbuildr/wiki
#>
#requires -version 3
[CmdletBinding()]
param(
    [string]$Nodeprefix,
    [String]$ClusterName,
    $IPaddress,
    $IPv6Prefix = "",
    [ValidateSet('8','24','32','48','64')]$IPv6PrefixLength = '8',
    [Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily,
    $Scriptdir = "\\vmware-host\Shared Folders\Scripts",
    $SourcePath = "\\vmware-host\Shared Folders\Sources",
    $logpath = "c:\Scripts"
)
$Nodescriptdir = "$Scriptdir\Node"
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
###########
$IPv6subnet = "$IPv6Prefix$IPv4Subnet"
$IPv6Address = "$IPv6Prefix$IPaddress"
Write-Verbose $IPv6PrefixLength
Write-Verbose $IPv6Address
Write-Verbose $IPv6subnet
Write-Verbose $AddressFamily
$Domain = $env:USERDOMAIN
$DomainController = (Get-ADDomainController).name
$NodeLIST = @()
$Clusternodes = Get-ADComputer -Filter * | where name -like "$Nodeprefix*"

if (!$ClusterName)
    {
    $Nodeprefix = $Nodeprefix.ToUpper()
    $Nodeprefix = $Nodeprefix.TrimEnd("NODE")
    $Clustername = $Nodeprefix+"Cluster"
    }
foreach ($Clusternode in $Clusternodes){
$NodeLIST += $Clusternode.Name
# write-Host " Enabling Cluster feature on Node $($Clusternode.Name)"
# Add-WindowsFeature -Name failover-Clustering -IncludeManagementTools -ComputerName $Clusternode.Name
}
switch ($AddressFamily)
    {
	
	"IPv4"
        {
        New-Cluster -Name $Clustername -Node $NodeLIST -StaticAddress $IPAddress -NoStorage
        }
	"IPv6"
        {
        New-Cluster -Name $Clustername -Node $NodeLIST
        Add-ClusterResource -Name "IPv6 Cluster Address" -ResourceType "IPv6 Address" -Group "Cluster Group"
        Get-ClusterResource "IPv6 Cluster Address" | Set-ClusterParameter –Multiple @{"Network"="Cluster Network 1"; "Address"= "$IPv6Address";"PrefixLength"=$IPv6PrefixLength}
        $res = Get-ClusterResource "Cluster Name" 
        Stop-ClusterResource -Name $res
        Set-ClusterResourceDependency -Dependency "[Ipv6 Cluster Address]" -InputObject $res
        Start-ClusterResource $res
        }
	"IPv4IPv6"
        {
        New-Cluster -Name $Clustername -Node $NodeLIST -StaticAddress $IPAddress -NoStorage
        Add-ClusterResource -Name "IPv6 Cluster Address" -ResourceType "IPv6 Address" -Group "Cluster Group"
        Get-ClusterResource "IPv6 Cluster Address" | Set-ClusterParameter –Multiple @{"Network"="Cluster Network 1"; "Address"= "$IPv6Address";"PrefixLength"=$IPv6PrefixLength}
        $res = Get-ClusterResource "Cluster Name" 
        Stop-ClusterResource -Name $res
        Set-ClusterResourceDependency -Dependency "[Ipv6 Cluster Address]" -InputObject $res
        Start-ClusterResource $res
        }
    }
#### generating fsw #####
Invoke-Command -ComputerName $DomainController -ScriptBlock {
param( $ClusterName, $Nodes )
New-Item -ItemType Directory -Path "C:\FSW_$ClusterName"
New-SmbShare -Name "FSW_$ClusterName" -FullAccess everyone -Path "C:\FSW_$ClusterName"
} -ArgumentList $ClusterName, $Nodes
##### set fsw quorum #####
Set-ClusterQuorum -FileShareWitness "\\$DomainController\FSW_$ClusterName"
Write-Host "Setting Cluster Access"
write-host "Changing PTR Record" 
########## changing cluster to register PTR record 
$res = Get-ClusterResource "Cluster Name" 
Set-ClusterParameter -Name PublishPTRRecords -Value 1 -InputObject $res
Stop-ClusterResource -Name $res
Start-ClusterResource -Name $res
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Pause
    }

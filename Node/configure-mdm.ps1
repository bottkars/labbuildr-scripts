<#
.Synopsis
   This script builds the scaleio mdm, sds and sdc for a hyper-v cluster
.DESCRIPTION
   labbuildr is a Self Installing Windows/Networker/NMM Environemnt Supporting Exchange 2013 and NMM 3.0
.LINK
   https://community.emc.com/blogs/bottk/2015/03/30/labbuildrbeta
#>
[CmdletBinding()]
param (
[parameter(mandatory = $false)][ValidateRange(1,10)]$CSVnum = 3,
[parameter(mandatory = $false)]$password = "Password123!",
[parameter(mandatory = $false)]$VolumeSize = "56",
[parameter(mandatory = $false)][switch]$singlemdm,
[parameter(mandatory = $false)][ValidateRange(1,2)]$scaleio_major = 1,

[switch]$reconfigure
)
$Success = ('0')
$Success_Warning = @('0','7','')
If ($reconfigure)
    { 
    $Exitcheck = $Success_Warning
    }
else
    {
    $Exitcheck = $Success
        }

#requires -version 3
#requires -module FailoverClusters
# 1. ######################################################################################################
# Initilization. you may want to adjust the Parameters for your needs
if (!(Get-Cluster . -ErrorAction SilentlyContinue) )
    {
    Write-Warning " This Deploymentmethod requires Windows Failover Cluster Configured"
    break
    }

$Location = $env:USERDOMAIN
$nodes = Get-ClusterNode
$Percentage = [math]::Round(100/$nodes.count)+1
write-verbose "fetching remote IP Addresses..."
$NodeIP = foreach ($node in $nodes){
Invoke-Command -ComputerName $node.name -ScriptBlock {param( $Location )
    (Get-NetIPAddress -AddressState Preferred -InterfaceAlias "vEthernet (External)" -SkipAsSource $false -AddressFamily IPv4 ).IPAddress
    } -ArgumentList $Location
}
$mdm_ipa = $NodeIP[0]
$mdm_ipb = $NodeIP[1]
$tb_ip = $NodeIP[2]
Write-Verbose $mdm_ipa
Write-Verbose $mdm_ipb
Write-Verbose $tb_ip
if ($singlemdm.IsPresent)
    {
    $mdm_ip ="$mdm_ipa"
    }
    else
    {
    $mdm_ip ="$mdm_ipa,$mdm_ipb"
    }
write-verbose " mdm will be at :$mdm_ip"
$Devicename = "$Location"+"_Disk_$Driveletter"
$VolumeName = "Volume_$Location"
$ProtectionDomainName = "PD_$Location"
$StoragePoolName = "SP_$Location"
$SystemName = "ScaleIO@$Location"
$FaultSetName = "Rack_"

# 2. ######################################################################################################
####### create MDM
## Manually run and accept license terms !!!
######################################################################################################
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now creating the Primary M[eta] D[ata] M[anager]"
    Pause
    }
Write-Host -ForegroundColor Magenta "Adding Primary MDM"
do {
    switch ($scaleio_major)
        {
        1
            {
            $sclicmd = scli --add_primary_mdm --primary_mdm_ip $mdm_ipa --mdm_management_ip $mdm_ip --accept_license # | out-null
            }
        2
            {
            $sclicmd = scli  --create_mdm_cluster --master_mdm_ip $mdm_ipa  --master_mdm_management_ip $mdm_ipa  --approve_certificate --accept_license #| Out-Null
            }
        }
            $sclicmd

    Write-Verbose $LASTEXITCODE
}
until ($LASTEXITCODE -in $Success_Warning)
Write-Host -ForegroundColor Green $sclicmd

# 3. ######################################################################################################
# add mdm, tb and switch cluster
if (!$reconfigure)
    {
    Write-Host -ForegroundColor Magenta "Attempting First Login to PrimaryMDM $mdm_ipa"
    do 
        {
        $Scli_login = scli --login --username admin --password admin --mdm_ip $mdm_ipa 2> $sclierror
        }
    until ($LASTEXITCODE -in $Success_Warning)
    Write-Host -ForegroundColor Magenta "Changing Password to $password"
    do
    {
    $Scli_password = scli --set_password --old_password admin --new_password $Password --mdm_ip $mdm_iP 2> $sclierror
    $Scli_login = scli --login --username admin --password $password --mdm_ip $mdm_iP 2> $sclierror
    Write-Verbose $LASTEXITCODE
    }
    until ($LASTEXITCODE -in $Exitcheck)
Write-Host -ForegroundColor Gray $Scli_password

if (!$singlemdm.IsPresent)
    {
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
    Write-Verbose "We are now adding the secondary M[eta] D[ata] M[anager] and T[ie [Breaker] abd form the Management Cluster"
    Write-Verbose "Open your ScalIO management UI and Connect to $mdm_ipa with admin / $Password and then to Monitor the Progress"
    Pause
    }
    do 
        {
        $scli_login = scli --login --username admin --password $Password --mdm_ip $mdm_iP  #
        Write-Verbose $LASTEXITCODE
        $Scli_login
        }
    until ($LASTEXITCODE -in $ExitCheck)
    Write-host -ForegroundColor Gray $Scli_login
    do 
        {
        switch ($scaleio_major)
            {
                1
                {
                $sclicmd = scli --add_secondary_mdm --mdm_ip $mdm_ipa --secondary_mdm_ip $mdm_ipb --mdm_ip $mdm_iP 2> $sclierror
                }
                2
                {
                $sclicmd = scli --add_standby_mdm --mdm_role manager --new_mdm_ip $mdm_ipb --mdm_ip $mdm_ipa 2> $sclierror
                }
            }

        Write-Verbose $LASTEXITCODE
        }
    until ($LASTEXITCODE -in $ExitCheck)
    Write-Host -ForegroundColor DarkGray $sclicmd
    Write-Host -ForegroundColor Magenta " ==>adding tiebreaker $tb_ip"
    do 
        {
        switch ($scaleio_major)
            {
                1
                {
                $sclicmd = scli --add_tb --tb_ip $tb_ip --mdm_ip $mdm_iP 2> $sclierror 
                }
                2
                {
                $sclicmd = scli --add_standby_mdm --mdm_role tb  --new_mdm_ip $tb_ip --mdm_ip $mdm_ipa  #2> $sclierror
                }
            }
        Write-Verbose $LASTEXITCODE
        }
    until ($LASTEXITCODE -in $Success_Warning)
    Write-Host -ForegroundColor Magenta " ==>switching to cluster mode"
    do 
        {
                switch ($scaleio_major)
            {
                1
                {
                scli --switch_to_cluster_mode --mdm_ip $mdm_iP 
                }
                2
                {
                scli --switch_cluster_mode --cluster_mode 3_node --add_slave_mdm_ip $mdm_ipb --add_tb_ip $tb_ip  --mdm_ip $mdm_ipa  2> $sclierror
                }
            }
        Write-Verbose $LASTEXITCODE
        }
    until ($LASTEXITCODE -in $Exitcheck)
    
    
    
    }








else
    {
    Write-Warning "Running ScaleIO ind SingleMDM Mode"
    }
}
# 4. ######################################################################################################
##### configure protection Domain and Storage Pool
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now configuring the Protection Domain and Storage Pool"
    Pause
    }
do 
    {
    $scli_login = scli --login --username admin --password $Password --mdm_ip $mdm_iP 2> $sclierror
    }
until ($LASTEXITCODE -in $ExitCheck)
Write-host -ForegroundColor Gray $Scli_login
Write-Host -ForegroundColor Magenta "Creating Prodection Domain $ProtectionDomainName"

do {
    scli --add_protection_domain --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_iP 2> $sclierror
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in $ExitCheck)

do 
    {
    $scli_login = scli --login --username admin --password $Password --mdm_ip $mdm_iP 2> $sclierror
    }
until ($LASTEXITCODE -in $ExitCheck)
Write-host -ForegroundColor Gray $Scli_login
foreach ($set in (1..3))
    {
    Write-Host -ForegroundColor Magenta "Creating Fault Set $FaultSetName$set"
    do {
        
        $add_faultset = scli --add_fault_set  --protection_domain_name $ProtectionDomainName --fault_set_name "$FaultSetName$Set"--mdm_ip $mdm_iP # | out-null
        Write-Verbose $LASTEXITCODE
        }
    until ($LASTEXITCODE -in $ExitCheck)
    Write-Host -ForegroundColor Gray $add_faultset
}
Write-Host -ForegroundColor Magenta "Creating Prodection Pool $StoragePoolName"

do {
    $add_pool = scli --add_storage_pool --storage_pool_name $StoragePoolName --protection_domain_name $ProtectionDomainName --mdm_ip $mdm_iP # | out-null
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in $ExitCheck)
Write-Host -ForegroundColor Gray $add_pool
Write-Host -ForegroundColor Magenta "Setting Spare policy to $Percentage"

do {
    $Set_spare = scli --modify_spare_policy --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --spare_percentage $Percentage --i_am_sure --mdm_ip $mdm_iP # | out-null
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in $ExitCheck)
Write-Host -ForegroundColor Gray $Set_spare
Write-Host -ForegroundColor Magenta "Renaming System"

do {
    $Rename_System = scli --rename_system --new_name "$SystemName" --mdm_ip $mdm_iP # | out-null
    Write-Verbose $LASTEXITCODE
    }
until ($LASTEXITCODE -in $ExitCheck)
Write-Host -ForegroundColor Gray $Rename_System

# 5. ######################################################################################################
#### Create SDS 

if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now adding the S[torage] D[ata] S[ervice] Nodes"
    Pause
    }

## will be mgrated to ,disk,disk,disk  usin $Disks -join ","
$Disks = @()
$Disks += (Get-ChildItem -Path C:\scaleio_devices\ -Recurse -Filter *.bin ).FullName
$Faultset_No = 1
$Devicename = "PhysicalDisk1"
foreach ($Nodenumber in (1..$nodes.count))
    {
    Write-Host -ForegroundColor Magenta "Adding Node $Nodenumber with $NodeIP[$Nodenumber-1]"
do 
    {    
    $add_sds = scli --add_sds --sds_ip $NodeIP[$Nodenumber-1] --device_path $Disks[0] --device_name $Devicename  --sds_name $Nodes[$Nodenumber-1].Name --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --fault_set_name "$($FaultSetName)$Faultset_No" --no_test --mdm_ip $mdm_iP # | out-null
    }
    until ($LASTEXITCODE -in $ExitCheck)
    Write-host -ForegroundColor Gray $add_sds
    $Faultset_No ++
    If ($Faultset_No -gt 3)
        {
        $Faultset_No = 1
        }
    }

# 6. ######################################################################################################
##### Add Disks to SDS Nodes # im am looking for Unformatted Fixed Drive with Driveletter
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now adding Additional Drives to the Storage Data Service Nodes"
    Pause
    }
do 
    {
    $scli_login = scli --login --username admin --password $Password --mdm_ip $mdm_iP 2> $sclierror
    }
until ($LASTEXITCODE -in $ExitCheck)
Write-host -ForegroundColor Gray $Scli_login

If ($Disks.Count -gt 1)
{
    foreach ($Disk in 2..($Disks.Count)) 
    {
    $Devicename = "PhysicalDisk$Disk"
    $Devicepath = $Disks[$Disk-1]
    Write-Verbose $Devicename
    Write-Verbose $Devicepath
    foreach ($Nodenumber in (1..$nodes.count))
        {
        Write-Host $Nodenumber, $NodeIP[$Nodenumber-1]
        do 
            {
            $add_sds_device = scli --add_sds_device --sds_ip $NodeIP[$Nodenumber-1] --device_path $Devicepath --device_name $Devicename --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --no_test --mdm_ip $mdm_iP # | out-null
            }
        until ($LASTEXITCODE -in $ExitCheck)
        Write-Host -ForegroundColor Gray $add_sds_device
        }
    }
}
# 7. ###################################################################################################### 
### connect sdc's
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "We are now adding the S[torage] D[ata] C[lients]"
    Pause
    }
$nodes = get-clusternode
foreach ($node in $nodes)

{
Write-Host -ForegroundColor Magenta  "Adding Storage Data Client $($Node.Name) to the ScaleIO grid"


Invoke-Command -ComputerName $node.name -ScriptBlock {param( $mdm_ip )

."C:\Program Files\emc\scaleio\sdc\bin\drv_cfg.exe" --add_mdm --ip $mdm_ip | out-null
."C:\Program Files\emc\scaleio\sdc\bin\drv_cfg.exe" --query_mdms

} -ArgumentList $mdm_ip
}

scli --mdm_ip $mdm_ip --query_all_sdc | Out-Null
foreach ($Nodenumber in (1..$nodes.count))
    {
    Write-Host -ForegroundColor Magenta "Query $($NodeIP[$Nodenumber-1])"   
    do 
        {
        $SDC_Query = scli --query_sdc --sdc_ip $NodeIP[$Nodenumber-1] --mdm_ip $mdm_iP 2> $sclierror
        Write-Verbose $LASTEXITCODE
        }
   
    until ($LASTEXITCODE -in $ExitCheck)
    $SDC_Query
    }

# 8. ######################################################################################################
### Create and map Volumes
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    Write-Verbose "Now Volume Creation and Mapping will start. Volumes will be added to the Cluster"
    Pause
    }
do 
    {
    $scli_login = scli --login --username admin --password $Password --mdm_ip $mdm_iP 2> $sclierror
    }
until ($LASTEXITCODE -in $ExitCheck)
Write-host -ForegroundColor Gray $Scli_login
 
foreach ($Volumenumber in 1..$CSVnum)
    {
    $VolumeName = "Vol_$Volumenumber"
    $Volquery = scli --mdm_ip $mdm_ip --query_all_volumes 2> $sclierror
    Write-Host -ForegroundColor Magenta "Create Volume $VolumeName"
    do 
        {
        # $newvol = scli --add_volume --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --size_gb $VolumeSize --thin_provisioned --volume_name $VolumeName --mdm_ip $mdm_iP  #| out-null 
        $newvol = scli --add_volume --protection_domain_name $ProtectionDomainName --storage_pool_name $StoragePoolName --size_gb $VolumeSize --thin_provisioned --volume_name $VolumeName --mdm_ip $mdm_ip 2> $sclierror
        Write-Verbose $LASTEXITCODE
        }

    until ($LASTEXITCODE -in $Success)
    Write-Host -ForegroundColor Green $newvol
    foreach ($Nodenumber in (1..$nodes.count))
        {
        Write-Host -ForegroundColor Magenta "Mapping $VolumeName to node $Nodenumber, $($NodeIP[$Nodenumber-1])"
        do
            {
            $MapVol =scli --map_volume_to_sdc --volume_name $VolumeName --sdc_ip $NodeIP[$Nodenumber-1] --allow_multi_map --mdm_ip $mdm_iP # | out-null
            # Write-Verbose $MapVol
            }
        until ($LASTEXITCODE -in $ExitCheck)
        Write-Host -ForegroundColor Green $MapVol
        }

    # join array to string, split at id remove spaces and select last
    $serial = (($newvol -join '').Split('ID')).Replace(' ','')[-1]
    # $serial = (($newvol -join '').Split('ID')).Replace(' ','')[-1]
    # 9. ######################################################################################################
    # initialize and import Cluster Disks
    ######## Disk
    Write-Output "Waiting for Disk to Appear in Failover Cluster"

    do
        {
        $Disk = Get-Disk  | where SerialNumber -match $serial
        if (!$disk)
            {
            write-host -NoNewline -ForegroundColor White "."
            }
        } 
     until ($Disk) 
    $Disk | Initialize-Disk -PartitionStyle GPT
    $Partition = $Disk  | New-Partition -UseMaximumSize
    $WinVolName =  "Scaleio_CSV_"+$VolumeName+"_"+$Serial
    $WinVollabel = "Scaleio_CSV_"+$VolumeName
    $Partition | Format-Volume -NewFileSystemLabel $WinVollabel -Confirm:$false
    $Disk = Get-Disk  | where SerialNumber -match  $Serial 
    $Clusterdisk = $Disk  | Add-ClusterDisk
    $Clusterdisk.Name = $WinVolName
    Get-ClusterResource -Name $Clusterdisk.Name | Add-ClusterSharedVolume
}


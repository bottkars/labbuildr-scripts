#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
BUILDDOMAIN=$3
CINDERBACKENDS=$4

PROJECTDOMAIN="default"
USERDOMAIN="default"
AUTHURL="http://$CONTROLLERNAME:35357/v3"

TENDEV="" #will get the developement tenent id later on
TENPROD="" #will get the production tenent id later on

ADMINBASECOMMAND="openstack --os-identity-api-version 3 --os-project-domain-name $PROJECTDOMAIN --os-user-domain-name $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url $AUTHURL "
DEVBASECOMMAND="--os-project-domain-name $PROJECTDOMAIN --os-user-domain-name $USERDOMAIN --os-project-name "$BUILDDOMAIN"_Developement --os-username Dev_Admin --os-password Password123! --os-auth-url $AUTHURL "
PRODBASECOMMAND="--os-project-domain-name $PROJECTDOMAIN --os-user-domain-name $USERDOMAIN --os-project-name "$BUILDDOMAIN"_Production --os-username Prod_Admin --os-password Password123! --os-auth-url $AUTHURL "

printf "
 ------------------------------------------
 | #### Configure Base Environment ##### |
 ------------------------------------------\n\n" | tee -a $LOGFILE
#printf " ## Create Additional Tenants \n"
	if ($ADMINBASECOMMAND project create --domain default --enable $BUILDDOMAIN"_Developement") >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Tenant "$BUILDDOMAIN"_Developement \n"; 	else printf " --> ERROR - Could not create Tenant "$BUILDDOMAIN"_Developement - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND project create --domain default --enable $BUILDDOMAIN"_Production") >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Tenant "$BUILDDOMAIN"_Production \n"; 	else printf " --> ERROR - Could not create Tenant "$BUILDDOMAIN"_Production - see $LOGFILE \n" | tee -a $LOGFILE; fi

#Get Tenant IDs
	TENDEV=$($ADMINBASECOMMAND project list | grep -i developement | awk '{print $2}')
	TENPROD=$($ADMINBASECOMMAND project list | grep -i production | awk '{print $2}')
	
printf " ## Create Additional Users \n"
	if ($ADMINBASECOMMAND user create --domain default --project $TENDEV --password Password123! --enable Dev_Admin) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created User Dev_Admin\n"; 	else printf " --> ERROR - Could not create User Dev_Admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND user create --domain default --project $TENDEV --password Password123! --enable Dev_User) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created User Dev_User \n"; 	else printf " --> ERROR - Could not create User Dev_User - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND user create --domain default --project $TENPROD --password Password123! --enable Prod_Admin) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created User Prod_Admin \n"; 	else printf " --> ERROR - Could not create user Prod_Admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND user create --domain default --project $TENPROD --password Password123! --enable Prod_User) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - created User Prod_User \n"; 	else printf " --> ERROR - Could not - create User Prod_User see $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ## Map User to Role and Project \n"
	if ($ADMINBASECOMMAND role add --project $TENDEV --user Dev_Admin admin) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Mapped user Dev_Admin to project "$BUILDDOMAIN"_Developement with role admin \n"; 	else printf " --> ERROR - Could not map user Dev_Admin to project "$BUILDDOMAIN"_Developement with role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND role add --project $TENDEV --user Dev_User user) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Mapped user Dev_Admin to project "$BUILDDOMAIN"_Developement with role user \n"; 	else printf " --> ERROR - Could not map user Dev_Admin to project "$BUILDDOMAIN"_Developement with role user - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND role add --project $TENPROD --user Prod_Admin admin) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Mapped user Prod_Admin to project "$BUILDDOMAIN"_Production with role admin \n"; 	else printf " --> ERROR - Could not map user Prod_Admin to project "$BUILDDOMAIN"_Production with role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND role add --project $TENPROD --user Prod_User user) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Mapped user Prod_Admin to project "$BUILDDOMAIN"_Production with role user \n"; 	else printf " --> ERROR - Could not map user Prod_Admin to project "$BUILDDOMAIN"_Production with role user - see $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ## Create Tenant Networks and Subnets \n"		
	if ($ADMINBASECOMMAND network create --project $TENDEV Developement_Net) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created Network Developement_Net for Tenant "$BUILDDOMAIN"_Developement\n"; 	else printf " --> ERROR - Could not create Network Developement_Net for Tenant "$BUILDDOMAIN"_Developement - see $LOGFILE \n" | tee -a $LOGFILE; fi	
	if ($ADMINBASECOMMAND subnet create --project $TENDEV --gateway 172.16.1.1 --allocation-pool start=172.16.1.11,end=172.16.1.250 --dns-nameserver 8.8.8.8 --subnet-range 172.16.1.0/24 --network Developement_Net Developement_SN  ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created Subnet Developement_SN for Tenant\n"; 	else printf " --> ERROR - Could not create Subnet Developement_SN for Tenant "$BUILDDOMAIN"_Developement - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND network create --project $TENPROD Production_Net) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created Network Production_Net for Tenant "$BUILDDOMAIN"_Production \n"; 	else printf " --> ERROR - Could not create Network Production_Net for Tenant "$BUILDDOMAIN"_Production - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND subnet create --project $TENPROD --gateway 172.16.2.1 --allocation-pool start=172.16.2.11,end=172.16.2.250 --dns-nameserver 8.8.8.8 --subnet-range 172.16.2.0/24 --network Production_Net Production_SN  ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created Subnet Production_SN for Tenant "$BUILDDOMAIN"_Production \n"; 	else printf " --> ERROR - Could not create Subnet Production_SN for Tenant "$BUILDDOMAIN"_Production - see $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ## Configure Admin related Network Settings \n"	
	if ($ADMINBASECOMMAND network create --provider-network-type flat --provider-physical-network public --external Internet) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Labbuildr just created the Internet =D \n"; 	else printf " --> ERROR - Labbuildr was not strong enough to create the Internet :'-( - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND subnet create --no-dhcp --gateway 192.168.2.4 --allocation-pool start=192.168.2.210,end=192.168.2.219 --dns-nameserver 192.168.2.4 --subnet-range 192.168.2.0/24 --network Internet Internet_SN ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Gave some IPs to the Internet. Created subnet Internet_SN on Network Internet \n"; 	else printf " --> ERROR - Could not create Subnet Internet_SN on Network Internet - see $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ## Create Router and add it to all networks \n"	
	if ($ADMINBASECOMMAND router create OSRouter) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created Router OSRouter \n"; 	else printf " --> ERROR - Could not create Router OSRouter - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if (neutron --os-project-domain-name $PROJECTDOMAIN --os-user-domain-name $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url $AUTHURL router-gateway-set --fixed-ip subnet_id=Internet_SN,ip_address=192.168.2.210 OSRouter Internet ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Set default Gateway on Router to Network Internet (IP 192.168.2.4) \n"; 	else printf " --> ERROR - Could not set default Gateway on Router to Network Internet (IP 192.168.2.4) - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND router add subnet OSRouter Developement_SN) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Added Router Interface to Developement_SN \n"; 	else printf " --> ERROR - Could not add Router Interface to Developement_SN - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND router add subnet OSRouter Production_SN ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Added Router Interface to Production_SN \n"; 	else printf " --> ERROR - Could not add Router Interface to Production_SN - see $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ## Get Cirros and create Image \n"	
	if (wget -O /tmp/cirros.img http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Downloaded cirros Image to /tmp/cirros.img \n"; 	else printf " --> ERROR - Could not download Cirros Image - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND image create --file /tmp/cirros.img --disk-format qcow2 --container-format bare --public cirros ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created Openstack Image Cirros \n"; 	else printf " --> ERROR - Could not create Openstack Image Cirros - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($ADMINBASECOMMAND flavor create --id 0 --ram 64 --disk 1 --vcpus 1 m1.nano) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created Flavor m1.nano \n"; 	else printf " --> ERROR - Could not create Flavor m1.nano - see $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ## Add Entries to Security Groups \n"
	if (nova $DEVBASECOMMAND secgroup-add-rule default icmp -1 -1 0.0.0.0/0) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Allowed ICMP in default Security Group in Tenant "$BUILDDOMAIN"_Developement \n"; 	else printf " --> ERROR - Could not allow ICMP in default Security Group in Tenant "$BUILDDOMAIN"_Developement - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if (nova $DEVBASECOMMAND secgroup-add-rule default tcp 22 22 0.0.0.0/0) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Allowed SSH in default Security Group in Tenant "$BUILDDOMAIN"_Developement \n"; 	else printf " --> ERROR - Could not allow SSH in default Security Group in Tenant "$BUILDDOMAIN"_Developement - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if (nova $PRODBASECOMMAND secgroup-add-rule default icmp -1 -1 0.0.0.0/0) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL - Allowed ICMP in default Security Group in Tenant "$BUILDDOMAIN"_Production \n"; 	else printf " --> ERROR - Could not allow ICMP in default Security Group in Tenant "$BUILDDOMAIN"_Production - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if (nova $PRODBASECOMMAND secgroup-add-rule default tcp 22 22 0.0.0.0/0) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL - Allowed SSH in default Security Group in Tenant "$BUILDDOMAIN"_Production \n"; 	else printf " --> ERROR - Could not allow SSH in default Security Group in Tenant "$BUILDDOMAIN"_Production - see $LOGFILE \n" | tee -a $LOGFILE; fi

if [[ $CINDERBACKENDS == *"scaleio"* ]]
		then
			printf ' ### Create Volume Types for ScaleIO_Thin / ScaleIO_Thick Provisioning \n'
					if ($ADMINBASECOMMAND volume type create ScaleIO_Thin) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created volume Type ScaleIO_Thin \n"; 	else printf " --> ERROR - Could not create volume Type ScaleIO_Thin - see $LOGFILE \n" | tee -a $LOGFILE; fi
					if ($ADMINBASECOMMAND volume type create ScaleIO_Thick) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created volume Type ScaleIO_Thick \n"; 	else printf " --> ERROR - Could not create volume Type ScaleIO_Thick - see $LOGFILE \n" | tee -a $LOGFILE; fi
				
				printf ' ### Set Properties for volume Types ScaleIO_Thin / ScaleIO_Thick \n'
					if ($ADMINBASECOMMAND volume type set --property sio:provisioning_type=thin ScaleIO_Thin) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Set sio:provisioning_type=thin for volume type ScaleIO_Thin \n"; 	else printf " --> ERROR - Could not set sio:provisioning_type=thin for volume type ScaleIO_Thin - see $LOGFILE \n" | tee -a $LOGFILE; fi
					if ($ADMINBASECOMMAND volume type set --property volume_backend_name=scaleio ScaleIO_Thin) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Set olume_backend_name=scaleio for volume type ScaleIO_Thin \n"; 	else printf " --> ERROR - Could not set olume_backend_name=scaleio for volume type ScaleIO_Thin - see $LOGFILE \n" | tee -a $LOGFILE; fi
				
					if ($ADMINBASECOMMAND volume type set --property sio:provisioning_type=thick ScaleIO_Thick) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Set sio:provisioning_type=thin for volume type ScaleIO_Thick \n"; 	else printf " --> ERROR - Could not set sio:provisioning_type=thick for volume type ScaleIO_Thick - see $LOGFILE \n" | tee -a $LOGFILE; fi
					if ($ADMINBASECOMMAND volume type set --property volume_backend_name=scaleio ScaleIO_Thick) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Set olume_backend_name=scaleio for volume type ScaleIO_Thick \n"; 	else printf " --> ERROR - Could not set olume_backend_name=scaleio for volume type ScaleIO_Thick - see $LOGFILE \n" | tee -a $LOGFILE; fi
		fi
### Deactivated because currently no supported unity driver for cinder in newton release
<<Deactivated		
if [[ $CINDERBACKENDS == *"unity"* ]]
		then
			printf ' ### Create Volume Types for Unity_iSCSI_Thin / Unity_iSCSI_Thick Provisioning \n'
					if ($ADMINBASECOMMAND volume type create Unity_iSCSI_Thin) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created volume Type Unity_iSCSI_Thin \n"; 	else printf " --> ERROR - Could not create volume Type Unity_iSCSI_Thin - see $LOGFILE \n" | tee -a $LOGFILE; fi					
					#### Deactivated because virtual Unity does not support Thick provision - if trying, its going to provision thin anyway
					#if ($ADMINBASECOMMAND volume type create Unity_iSCSI_Thick) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Created volume Type Unity_iSCSI_Thick \n"; 	else printf " --> ERROR - Could not create volume Type Unity_iSCSI_Thick - see $LOGFILE \n" | tee -a $LOGFILE; fi
								
				printf ' ### Set Properties for volume Types Unity_iSCSI_Thin / Unity_iSCSI_Thicn \n'
					if ($ADMINBASECOMMAND volume type set --property storagetype:provisioning=thin Unity_iSCSI_Thin) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Set storagetype:provisioning=thin for volume type Unity_iSCSI_Thin \n"; 	else printf " --> ERROR - Could not set storagetype:provisioning=thin for volume type Unity_iSCSI_Thin - see $LOGFILE \n" | tee -a $LOGFILE; fi
					if ($ADMINBASECOMMAND volume type set --property volume_backend_name=unity Unity_iSCSI_Thin) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Set volume_backend_name=unity for volume type Unity_iSCSI_Thin \n"; 	else printf " --> ERROR - Could not set volume_backend_name=unity for volume type Unity_iSCSI_Thin - see $LOGFILE \n" | tee -a $LOGFILE; fi
					
					#### Deactivated because virtual Unity does not support Thick provision - if trying, its going to provision thin anyway
					#if ($ADMINBASECOMMAND volume type set --property storagetype:provisioning=thick Unity_iSCSI_Thick) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Set storagetype:provisioning=thick for volume type Unity_iSCSI_Thick \n"; 	else printf " --> ERROR - Could not set storagetype:provisioning=thick for volume type Unity_iSCSI_Thick - see $LOGFILE \n" | tee -a $LOGFILE; fi
					#if ($ADMINBASECOMMAND volume type set --property volume_backend_name=unity Unity_iSCSI_Thick) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Set volume_backend_name=unity for volume type Unity_iSCSI_Thick \n"; 	else printf " --> ERROR -  Could not set volume_backend_name=unity for volume type Unity_iSCSI_Thick - see $LOGFILE \n" | tee -a $LOGFILE; fi
				
		fi		
Deactivated
printf "
 ------------------------------------------
 | #### Finished Base Environment ##### |
 ------------------------------------------\n\n" | tee -a $LOGFILE
#!/bin/bash
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

PROJECTDOMAIN="default"
USERDOMAIN="default"
AUTHURL="http://$(hostname):35357/v3"
LABDOMAIN=$1
TENDEV="" #will get the developement tenent id later on
TENPROD="" #will get the production tenent id later on

printf " #### Start Configuring the environment \n"

printf " ### Create Additional Tenants \n"

	if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
	project create --enable $LABDOMAIN"_Developement")  >> /tmp/os_logs/conf_env.log 2>&1; then
		printf " --> Tenant "$LABDOMAIN"_Developement has been created.\n"
	else 
		printf " --> Could not create Tenant "$LABDOMAIN"_Developement - see /tmp/os_logs/env_conf.log\n"
	fi
	
	if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
	project create --enable $LABDOMAIN"_Production")  >> /tmp/os_logs/conf_env.log 2>&1; then
		printf " --> Tenant "$LABDOMAIN"_Production has been created.\n"
	else 
		printf " --> Could not create Tenant "$LABDOMAIN"_Production - see /tmp/os_logs/env_conf.log\n"
	fi

	
#Get Tenant IDs
	TENDEV=$(openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL project list | grep -i developement | awk '{print $2}')
	TENPROD=$(openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL project list | grep -i production | awk '{print $2}')

printf " ### Create Additional Users \n"
		if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
		 user create --project $TENDEV --password Password123! --enable Dev_Admin)  >> /tmp/os_logs/conf_env.log 2>&1; then 
			printf " --> Created User Dev_Admin\n"
		else 
			printf " --> Could not create User Dev_Admin \n"
		fi
		
if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
		 user create --project $TENDEV --password Password123! --enable Dev_User)  >> /tmp/os_logs/conf_env.log 2>&1; then 
			printf " --> Created User Dev_User\n"
		else 
			printf " --> Could not create User Dev_User\n"
		fi

		if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
		 user create --project $TENPROD --password Password123! --enable Prod_Admin)  >> /tmp/os_logs/conf_env.log 2>&1; then 
			printf " --> Created User Prod_Admin\n"
		else 
			printf " --> Could not create User Prod_Admin \n"
		fi
		
if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
		 user create --project $TENPROD --password Password123! --enable Prod_User)  >> /tmp/os_logs/conf_env.log 2>&1; then 
			printf " --> Created User Prod_User\n"
		else 
			printf " --> Could not create User Prod_User\n"		
		fi
		
printf " ### Map User to Role and Project \n"
	if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
		role add --project $TENDEV --user Dev_Admin admin) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Mapped user Dev_Admin to project "$LABDOMAIN"_Developement with role admin \n"
		else 
			printf " --> Could not map user Dev_Admin to project "$LABDOMAIN"_Developement with role admin  - see /tmp/os_logs/conf_env.log \n"
	fi

	if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
		role add --project $TENDEV --user Dev_User user) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Mapped user Dev_User to project "$LABDOMAIN"_Developement with role user \n"
		else 
			printf " --> Could not map user Dev_user to project "$LABDOMAIN"_Developement with role user  - see /tmp/os_logs/conf_env.log \n"
	fi

	if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
		role add --project $TENPROD --user Prod_Admin admin) >> /tmp/os_logs/conf_env.log 2>&1;	then
			printf " --> Mapped user Prod_Admin to project "$LABDOMAIN"_Production with role admin \n"
		else 
			printf " --> Could not map user Prod_Admin to project "$LABDOMAIN"_Production with role admin  - see /tmp/os_logs/conf_env.log \n"
	fi

		if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
		role add --project $TENPROD --user Prod_User user) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Mapped user Prod_User to project "$LABDOMAIN"_Production with role user \n"
		else 
			printf " --> Could not map user Prod_user to project "$LABDOMAIN"_Production with role user  - see /tmp/os_logs/conf_env.log \n"
	fi

printf " ### Create Tenant Networks and Subnets \n"	
	
		if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
			network create --project  $TENDEV Developement_Net) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Created Network Developement_Net for Tenant "$LABDOMAIN"_Developement\n"
		else
			printf " --> Could not create Network Developement_Net for Tenant "$LABDOMAIN"_Developement\n - see /tmp/os_logs/conf_env.log \n"
		fi
	
		if (neutron --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL  \
		subnet-create --tenant-id $TENDEV --gateway 172.16.1.1 --allocation-pool start=172.16.1.11,end=172.16.1.250 --dns-nameserver 8.8.8.8 --name Developement_SN Developement_Net 172.16.1.0/24) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Created Subnet Developement_SN for Tenant "$LABDOMAIN"_Developement on Network Developement_Net\n"
		else
			printf " --> Could not create Subnet Developement_SN for Tenant "$LABDOMAIN"_Developement on Network Developement_Net - see /tmp/os_logs/conf_env.log \n"
		fi
	
		if (openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
			network create --project  $TENPROD Production_Net) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Created Network Production_Net for Tenant "$LABDOMAIN"_Production\n"
		else
			printf " --> Could not create Network Production_Net for Tenant "$LABDOMAIN"_Production\n"
		fi
	
		if (neutron --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL  \
		subnet-create --tenant-id $TENPROD --gateway 172.16.2.1 --allocation-pool start=172.16.2.11,end=172.16.2.250 --dns-nameserver 8.8.8.8 --name Production_SN Production_Net 172.16.2.0/24) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Created Subnet Production_SN for Tenant "$LABDOMAIN"_Production on Network Production_Net\n"
		else
			printf " --> Could not create Subnet Production_SN for Tenant "$LABDOMAIN"_Production Network Production_Net - see /tmp/os_logs/conf_env.log \n"
		fi

printf " ### Configure Admin related Network Settings \n"
	printf " ## Create Internet Network (Yes labbuildr can do this!) \n"	
		if (neutron --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL   \
		 net-create --shared --provider:physical_network public --provider:network_type flat --router:external Internet) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> labbuildr just created the Internet!\n"
		else
			printf " --> Could not create the Internet  - see /tmp/os_logs/conf_env.log \n"
		fi

	if (neutron --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL  \
		subnet-create --disable-dhcp --gateway 192.168.2.4 --allocation-pool start=192.168.2.210,end=192.168.2.219 --dns-nameserver 192.168.2.4 --name Internet_SN Internet 192.168.2.0/24) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Gave some IPs to the Internet. Created subnet Internet_SN on Network Internet \n"
	else
			printf " --> Could not create Subnet Internet_SN on Network Internet - see /tmp/os_logs/conf_env.log \n"
	fi

printf " ### Create Router and add it to all networks \n"
	if (neutron --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL  \
		router-create OSRouter) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Created Router OSRouter \n"
	else
			printf " --> Could not create Router OSRouter - see /tmp/os_logs/conf_env.log \n"
	fi
	
	if (neutron --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL  \
		router-gateway-set OSRouter Internet ) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Set default Gateway on Router to Network Internet (IP 192.168.2.4) \n"
	else
			printf " --> Could not set default Gateway on Router to Network Internet (IP 192.168.2.4) - see /tmp/os_logs/conf_env.log \n"
	fi

	if (neutron --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL  \
		router-interface-add OSRouter Developement_SN ) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Added Router Interface to Developement_SN \n"
	else
			printf " --> Could not add Router Interface to Developement_SN - see /tmp/os_logs/conf_env.log \n"
	fi

	if (neutron --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL  \
		router-interface-add OSRouter Production_SN ) >> /tmp/os_logs/conf_env.log 2>&1; then
			printf " --> Added Router Interface to Production_SN \n"
	else
			printf " --> Could not add Router Interface to Production_SN - see /tmp/os_logs/conf_env.log \n"
	fi

printf " ### Get Cirros and create Image \n"
	if wget -O /tmp/cirros.img http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img >> /tmp/os_logs/conf_env.log 2>&1; then printf " --> Downloaded image to /tmp/cirros.img \n"; else printf " --> Could not download Image - see /tmp/os_logs/conf_env.log \n"; fi
	
	if (glance --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL \
		image-create --name "cirros" --file /tmp/cirros.img --disk-format qcow2 --container-format bare --visibility public) >> /tmp/os_logs/conf_env.log 2>&1; then 
		printf " --> Created Cirros Image\n"
	else
		printf " --> Could not create Image - see /tmp/os_logs/conf_env.log \n"
	fi
	
	if (nova --os-project-domain-id $PROJECTDOMAIN  --os-project-name admin --os-user-domain-id $USERDOMAIN --os-username admin --os-password Password123! --os-auth-url $AUTHURL \
		flavor-create m1.nano 0 64 1 1) >> /tmp/os_logs/conf_env.log 2>&1; then 
		printf " --> Created Flavor m1.nano \n"
	else
		printf " --> Could not create Flavor m1.nano - see /tmp/os_logs/conf_env.log \n"
	fi

	
printf " ### Add Entries to Security Groups \n"
	if (nova --os-project-domain-id $PROJECTDOMAIN  --os-project-id $TENDEV --os-user-domain-id $USERDOMAIN --os-username Dev_Admin --os-password Password123! --os-auth-url $AUTHURL \
		secgroup-add-rule default icmp -1 -1 0.0.0.0/0) >> /tmp/os_logs/conf_env.log 2>&1; then 
		printf " --> Allowed ICMP in default Security Group in Tenant "$LABDOMAIN"_Developement \n"
	else
		printf " --> Could not allow ICMP in default Security Group in Tenant "$LABDOMAIN"_Developement \n"
	fi

	if (nova --os-project-domain-id $PROJECTDOMAIN  --os-project-id $TENDEV --os-user-domain-id $USERDOMAIN --os-username Dev_Admin --os-password Password123! --os-auth-url $AUTHURL \
		secgroup-add-rule default tcp 22 22 0.0.0.0/0 ) >> /tmp/os_logs/conf_env.log 2>&1; then 
		printf " --> Allowed SSH in default Security Group in Tenant "$LABDOMAIN"_Developement \n"
	else
		printf " --> Could not allow SSH in default Security Group in Tenant "$LABDOMAIN"_Developement \n"
	fi
	
	if (nova --os-project-domain-id $PROJECTDOMAIN  --os-project-id $TENPROD --os-user-domain-id $USERDOMAIN --os-username Prod_Admin --os-password Password123! --os-auth-url $AUTHURL \
		secgroup-add-rule default icmp -1 -1 0.0.0.0/0) >> /tmp/os_logs/conf_env.log 2>&1; then 
		printf " --> Allowed ICMP in default Security Group in Tenant "$LABDOMAIN"_Production \n"
	else
		printf " --> Could not allow ICMP in default Security Group in Tenant "$LABDOMAIN"_Production \n"
	fi
	
	if (nova --os-project-domain-id $PROJECTDOMAIN  --os-project-id $TENPROD --os-user-domain-id $USERDOMAIN --os-username Prod_Admin --os-password Password123! --os-auth-url $AUTHURL \
		secgroup-add-rule default tcp 22 22 0.0.0.0/0 ) >> /tmp/os_logs/conf_env.log 2>&1; then 
		printf " --> Allowed SSH in default Security Group in Tenant "$LABDOMAIN"_Production \n"
	else
		printf " --> Could not allow SSH in default Security Group in Tenant "$LABDOMAIN"_Production \n"
	fi

printf ' ### Create Volume Types for Thin / Thick Provisioning \n'
		if openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
			volume type create thin >> /tmp/os_logs/conf_env.log 2>&1; then
				printf " --> Created volume Type thin \n"
		else 
			printf " --> Could not create volume Type thin - see /tmp/os_logs/conf_env.log\n"
		fi
		
		if openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
			volume type create thick >> /tmp/os_logs/conf_env.log 2>&1; then
				printf " --> Created volume Type thick \n "
		else
			printf " --> Could not create volume Type thick - see /tmp/os_logs/conf_env.log\n"
		fi
	
	printf ' ### Set Properties for volume Types Thin / Thick \n'
		if openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
			volume type set --property sio:provisioning_type=thin thin >> /tmp/os_logs/conf_env.log 2>&1; then
				printf " --> Set sio:provisioning_type=thin for volume type thin \n"
		else
				printf " --> Could not set sio:provisioning_type=thin for volume type thin - see /tmp/os_logs/conf_env.log\n "
		fi
			
		if openstack --os-project-domain-id $PROJECTDOMAIN --os-user-domain-id $USERDOMAIN --os-project-name admin --os-username admin --os-password Password123! --os-auth-url  $AUTHURL \
			volume type set --property sio:provisioning_type=thick thick >> /tmp/os_logs/conf_env.log 2>&1; then
				printf " --> Set sio:provisioning_type=thick for volume type thick \n"
		else
				printf " --> Could not set sio:provisioning_type=thick for volume type thick - see /tmp/os_logs/conf_env.log\n "
		fi
		
	
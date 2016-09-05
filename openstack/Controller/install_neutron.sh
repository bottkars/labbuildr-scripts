#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALIP=$2

printf "\n\n #### Start Neutron Installation \n"

### Install
	printf " ### Install Packages "
		if apt-get install neutron-server neutron-plugin-ml2 neutron-plugin-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent python-neutronclient -y >> /tmp/os_logs/neutron.log 2>&1; then
					printf $green " --> done"
		else
			printf $red " --> Could not install Neutron Packages - see /tmp/os_logs/neutron.log"
		fi

#Copy Predefined Configs
	printf " ### Configure Neutron \n"
		cp ./configs/neutron.conf /etc/neutron/neutron.conf
		cp ./configs/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
		cp ./configs/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
		cp ./configs/l3_agent.ini /etc/neutron/l3_agent.ini
		cp ./configs/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
		cp ./configs/dnsmasq-neutron.conf /etc/neutron/dnsmasq-neutron.conf
		cp ./configs/metadata_agent.ini /etc/neutron/metadata_agent.ini

		#Configure Neutron Configs
		sed -i '/nova_url = */c\nova_url = http://'$LOCALHOSTNAME':8774/v2' /etc/neutron/neutron.conf
		sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://neutron:Password123!@'$LOCALHOSTNAME'/neutron' /etc/neutron/neutron.conf
		sed -i '/rabbit_host = */c\rabbit_host = '$LOCALHOSTNAME /etc/neutron/neutron.conf
		sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000' /etc/neutron/neutron.conf
		sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357' /etc/neutron/neutron.conf
		sed -i '/local_ip = */c\local_ip = '$LOCALIP /etc/neutron/plugins/ml2/linuxbridge_agent.ini
		sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000' /etc/neutron/metadata_agent.ini
		sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357' /etc/neutron/metadata_agent.ini
	printf $green " --> done\n"
	
	#Add neutron section to nova.conf
		echo "
[neutron]
url = http://$LOCALHOSTNAME:9696
auth_url = http://$LOCALHOSTNAME:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
region_name = RegionOne
project_name = service
username = neutron
password = Password123!
service_metadata_proxy = True
metadata_proxy_shared_secret = Password123!
" >> /etc/nova/nova.conf

#Populate Neutron Database
	printf " ### Populate Neutron Database "
		if su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron >> /tmp/os_logs/neutron.log 2>&1; then
	printf $green " --> done"	
		else
			printf $red " --> Could not populate Neutron Database - see /tmp/os_logs/neutron.log"		
		fi

#Restart Services
		printf " ### Restart Neutron and Neutron related Services"
			if service nova-api restart >> /tmp/os_logs/neutron.log 2>&1; 										then printf " --> Restart Nova-api Service done\n"; 							else printf  " --> Could not restart Nova-api Service - see /tmp/os_logs/neutron.log\n"; fi
			if service neutron-server restart >> /tmp/os_logs/neutron.log 2>&1; 								then printf " --> Restart neutron-server done\n"; 								else printf  " --> Could not restart neutron-server Service - see /tmp/os_logs/neutron.log\n"; fi
			if service neutron-plugin-linuxbridge-agent restart >> /tmp/os_logs/neutron.log 2>&1; 	then printf " --> Restart neutron-plugin-linuxbridge-agent done\n"; 	else printf  " --> Could not restart neutron-plugin-linuxbridge-agent Service - see /tmp/os_logs/neutron.log\n"; fi
			if service neutron-dhcp-agent restart >> /tmp/os_logs/neutron.log 2>&1; 						then printf " --> Restart neutron-dhcp-agent done\n"; 						else printf  " --> Could not restart neutron-dhcp-agent Service - see /tmp/os_logs/neutron.log\n"; fi
			if service neutron-metadata-agent restart >> /tmp/os_logs/neutron.log 2>&1; 				then printf " --> Restart neutron-metadata-agent done\n"; 				else printf  " --> Could not restart neutron-metadata-agent Service - see /tmp/os_logs/neutron.log\n"; fi
			if service neutron-l3-agent restart >> /tmp/os_logs/neutron.log 2>&1; 							then printf " --> Restart neutron-l3-agent done\n"; 							else printf  " --> Could not restart neutron-l3-agent Service - see /tmp/os_logs/neutron.log\n"; fi

#Remove Neutron Dummy Database
	printf " ### Remove Neutron  Dummy Database"
		rm -f /var/lib/neutron/neutron.sqlite
	printf $green " --> done"
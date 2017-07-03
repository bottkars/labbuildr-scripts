#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALIP=$1
CONTROLLERIP=$2
CONTROLLERNAME=$3

printf "\n\n #### Start Neutron Installation \n"

### Install
	printf " ### Install Packages "
		if apt-get install neutron-plugin-linuxbridge-agent conntrack -y >> /tmp/os_logs/neutron.log 2>&1; then
					printf $green " --> done"
		else
			printf $red " --> Could not install Neutron Packages - see /tmp/os_logs/neutron.log"
		fi

#Copy Predefined Configs
	printf " ### Configure Neutron \n"
		cp ./configs/neutron.conf /etc/neutron/neutron.conf
		cp ./configs/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
		#Configure Neutron Configs
		sed -i '/rabbit_host = */c\rabbit_host = '$CONTROLLERNAME /etc/neutron/neutron.conf
		sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERIP':5000' /etc/neutron/neutron.conf
		sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/neutron/neutron.conf
		sed -i '/local_ip = */c\local_ip = '$LOCALIP /etc/neutron/plugins/ml2/linuxbridge_agent.ini
		#Add neutron section to nova.conf
		echo "
[neutron]
url = http://$CONTROLLERNAME:9696
auth_url = http://$CONTROLLERNAME:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
region_name = RegionOne
project_name = service
username = neutron
password = Password123!
" >> /etc/nova/nova.conf
	printf $green " --> done\n"
	
#Restart Services
	printf " ### Restart Neutron and Neutron related Services"
		if service nova-compute restart >> /tmp/os_logs/neutron.log 2>&1; 								then printf " --> Restart Nova-compute Service done\n"; 				else printf  " --> Could not restart Nova-compute Service - see /tmp/os_logs/neutron.log\n"; fi
		if service neutron-plugin-linuxbridge-agent restart >> /tmp/os_logs/neutron.log 2>&1; 	then printf " --> Restart neutron-plugin-linuxbridge-agent done\n"; 	else printf  " --> Could not restart neutron-plugin-linuxbridge-agent Service - see /tmp/os_logs/neutron.log\n"; fi


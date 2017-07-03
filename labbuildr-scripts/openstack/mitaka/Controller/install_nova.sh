#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALIP=$2

printf "\n\n #### Start Nova Installation \n"

	### Install
	printf " ### Install Packages "
		if apt-get install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient -y >> /tmp/os_logs/nova.log 2>&1; then
					printf " --> done \n"
		else
			printf " ERROR --> Could not install Nova Packages - see /tmp/os_logs/nova.log"
		fi	

	printf " ### Configure Nova "
			# Create new Nova File
			echo "[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
enabled_apis=ec2,osapi_compute,metadata
rpc_backend = rabbit
auth_strategy = keystone
my_ip = $LOCALIP
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
metadata_host = \$my_ip

[api_database]
connection = mysql+pymysql://nova:Password123!@$LOCALHOSTNAME/nova_api

[database]
connection = mysql+pymysql://nova:Password123!@$LOCALHOSTNAME/nova

[oslo_messaging_rabbit]
rabbit_host = $LOCALHOSTNAME
rabbit_userid = nova_compute
rabbit_password = Password123!

[keystone_authtoken]
auth_uri = http://$LOCALHOSTNAME:5000
auth_url = http://$LOCALHOSTNAME:35357
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = Password123!

[vnc]
vncserver_listen = \$my_ip
vncserver_proxyclient_address = \$my_ip

[glance]
api_servers = http://$LOCALHOSTNAME:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

" > /etc/nova/nova.conf	
	printf " --> done\n"
	
#Populate the nova database
	printf " ### Populate Nova Databases \n"
		if su -s /bin/sh -c "nova-manage db sync" nova >> /tmp/os_logs/nova.log 2>&1; then
			printf " --> Populated Nova Database.\n"
		else
			printf $red " ERROR --> Could not populate Nova Database - see /tmp/os_logs/nova.log"		
		fi
		
		if su -s /bin/sh -c "nova-manage api_db sync" nova >> /tmp/os_logs/nova.log 2>&1; then
			printf " --> Populated Nova-Api Database.\n"
		else
			printf " ERROR --> Could not populate Nova-Api Database - see /tmp/os_logs/nova.log"		
		fi
		
#Restart Services
		printf " ### Restart Nova Services\n"
			if service nova-api restart >> /tmp/os_logs/nova.log 2>&1; 				then printf " --> Restart Nova-api done\n"; 				else printf  " ERROR --> Could not restart Nova-api Service - see /tmp/os_logs/nova.log\n";fi
			if service nova-consoleauth restart >> /tmp/os_logs/nova.log 2>&1; 	then printf " --> Restart Nova-consoleauth done\n"; else printf  " ERROR --> Could not restart Nova-consoleauth Service - see /tmp/os_logs/nova.log\n";fi
			if service nova-scheduler restart >> /tmp/os_logs/nova.log 2>&1; 		then printf " --> Restart Nova-scheduler done\n"; 	else printf  " ERROR --> Could not restart Nova-scheduler Service - see /tmp/os_logs/nova.log\n";fi
			if service nova-conductor restart >> /tmp/os_logs/nova.log 2>&1; 	then printf " --> Restart Nova-conductor done\n"; 	else printf  " ERROR --> Could not restart Nova-conductor Service - see /tmp/os_logs/nova.log\n";fi
			if service nova-novncproxy restart >> /tmp/os_logs/nova.log 2>&1; 	then printf " --> Restart Nova-novncproxy done\n"; 	else printf  " ERROR --> Could not restart Nova-novncproxy Service - see /tmp/os_logs/nova.log\n";fi

	#Remove nova dummy database
	printf " ### Remove Nova Dummy Database"
		rm -f /var/lib/nova/nova.sqlite
	printf $green " --> done"
	
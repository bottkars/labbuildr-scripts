#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALHOSTIP=$2
SIO_GW=$3
SIO_PD=$4
SIO_SP=$5

printf "\n\n #### Start Cinder Installation \n"

### Install
	printf " ### Install Packages "
		if apt-get install cinder-api cinder-scheduler python-cinderclient cinder-volume -y >> /tmp/os_logs/cinder.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not install Cinder Packages - see /tmp/os_logs/cinder.log"
		fi		
		
#Copy Predefined Configs
	printf " ### Configure Cinder "
		cp ./configs/cinder.conf /etc/cinder/cinder.conf

#Configure
		echo "[cinder]
os_region_name = RegionOne" >> /etc/nova/nova.conf
		sed -i '/my_ip = */c\my_ip = '$LOCALHOSTIP /etc/cinder/cinder.conf
		sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://cinder:Password123!@'$LOCALHOSTNAME'/cinder' /etc/cinder/cinder.conf
		sed -i '/rabbit_host = */c\rabbit_host = '$LOCALHOSTNAME /etc/cinder/cinder.conf
		sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000' /etc/cinder/cinder.conf
		sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357' /etc/cinder/cinder.conf
		sed -i '/san_ip = */c\san_ip = '$SIO_GW /etc/cinder/cinder.conf
		sed -i '/sio_protection_domain_name = */c\sio_protection_domain_name = '$SIO_PD /etc/cinder/cinder.conf
		sed -i '/sio_storage_pool_name =*/c\sio_storage_pool_name = '$SIO_SP /etc/cinder/cinder.conf
		sed -i '/sio_storage_pools = */c\sio_storage_pools = '$SIO_PD':'$SIO_SP /etc/cinder/cinder.conf
	printf $green " --> done"

#Populate Database
	printf " ### Populate Cinder Database "
		if su -s /bin/sh -c "cinder-manage db sync" cinder >> /tmp/os_logs/cinder.log 2>&1; then
	printf $green " --> done"
		else
			printf $red " --> Could not populate Cinder Database - see /tmp/os_logs/cinder.log"		
		fi
				
#Restart Services
		printf " ### Restart Cinder and Cinder related Services\n"
			if service nova-api restart >> /tmp/os_logs/nova.log 2>&1; 				then printf " --> Restart Nova-api done\n"; 				else printf  " --> Could not restart Nova-api Service - see /tmp/os_logs/cinder.log\n"; fi
			if service cinder-api restart >> /tmp/os_logs/cinder.log 2>&1; 			then printf " --> Restart cinder-api done\n"; 			else printf  " --> Could not restart cinder-api Service - see /tmp/os_logs/cinder.log\n"; fi
			if service cinder-scheduler restart >> /tmp/os_logs/cinder.log 2>&1; 	then printf " --> Restart cinder-scheduler done\n";	else printf  " --> Could not restart cinder-scheduler Service - see /tmp/os_logs/cinder.log\n"; fi
			if service cinder-volume restart >> /tmp/os_logs/cinder.log 2>&1; 		then printf " --> Restart cinder-volume done\n"; 		else printf  " --> Could not restart cinder-volume Service - see /tmp/os_logs/cinder.log\n"; fi

##Remove cinder dummy database
	printf " ### Remove Cinder Dummy Database"
		rm -f /var/lib/cinder/cinder.sqlite
	printf $green " --> done"	
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
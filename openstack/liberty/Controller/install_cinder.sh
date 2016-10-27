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
UNITY_IP=$6
UNITY_POOL=$7
CINDERBACKENDS=$8

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
		echo "[cinder]
os_region_name = RegionOne" >> /etc/nova/nova.conf
		sed -i '/my_ip = */c\my_ip = '$LOCALHOSTIP /etc/cinder/cinder.conf
		sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://cinder:Password123!@'$LOCALHOSTNAME'/cinder' /etc/cinder/cinder.conf
		sed -i '/rabbit_host = */c\rabbit_host = '$LOCALHOSTNAME /etc/cinder/cinder.conf
		sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000' /etc/cinder/cinder.conf
		sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357' /etc/cinder/cinder.conf
		sed -i '/enabled_backends=* /c\enabled_backends='$CINDERBACKENDS /etc/cinder/cinder.conf
	
	if [[ $CINDERBACKENDS == *"scaleio"* ]]
		then
		echo "[scaleio]
san_ip = $SIO_GW
sio_protection_domain_name = $SIO_PD
sio_storage_pool_name = $SIO_SP
sio_storage_pools = $SIO_PD:$SIO_SP
san_login = admin
san_password = Password123!
san_thin_provision = true
volume_driver=cinder.volume.drivers.emc.scaleio.ScaleIODriver
volume_backend_name=scaleio" >> /etc/cinder/cinder.conf
		fi
		
	if [[ $CINDERBACKENDS == *"unity"* ]]
		then
			echo "[unity]
storage_protocol = iSCSI
storage_pool_names = $UNITY_POOL
san_ip = $UNITY_IP
san_login = Local/admin
san_password = Password123!
volume_driver = cinder.volume.drivers.emc.emc_unity.EMCUnityDriver
volume_backend_name = unity" >> /etc/cinder/cinder.conf
		fi
	
	
	
	
	
	
#Populate Database
	printf " ### Populate Cinder Database "
		if su -s /bin/sh -c "cinder-manage db sync" cinder >> /tmp/os_logs/cinder.log 2>&1; then
	printf $green " --> done"
		else
			printf $red " --> Could not populate Cinder Database - see /tmp/os_logs/cinder.log"		
		fi

printf " ### Get Unity Driver " 
	curl -o /usr/lib/python2.7/dist-packages/cinder/volume/drivers/emc/emc_unity.py https://raw.githubusercontent.com/emc-openstack/unity-cinder-driver/liberty/emc_unity.py >> /tmp/os_logs/cinder.log 2>&1; 
	
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
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
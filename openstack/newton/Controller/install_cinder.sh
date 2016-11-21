#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
CONTROLLERIP=$3
SIO_GW=$4
SIO_PD=$5
SIO_SP=$6
INSTALLPATH=$7
UNITY_IP=$8
UNITY_POOL=$9
CINDERBACKENDS=${10}

printf "
  --------------------------------------
 | #### Start Cinder Installation ##### |
  --------------------------------------\n\n"	 | tee -a $LOGFILE
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install cinder-api cinder-scheduler cinder-volume -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Cinder Packages\n"; else printf " --> ERROR - could not install Cinder Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
	if (cp ${INSTALLPATH}/configs/cinder.conf /etc/cinder/cinder.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied cinder.conf file \n"; else printf " --> ERROR - Could not copy cinder.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	
	
printf " ### Configure Cinder \n" | tee -a $LOGFILE	
	if (echo "[cinder]
os_region_name = RegionOne" >> /etc/nova/nova.conf); then printf " --> SUCCESSFUL - Added Cinder to Nova Config\n"; else printf " --> ERROR - could not  add Cinder to Nova Config- Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

	sed -i '/my_ip = */c\my_ip = '$CONTROLLERIP /etc/cinder/cinder.conf
	sed -i '/memcached_servers = */c\memcached_servers = '$CONTROLLERNAME':11211' /etc/cinder/cinder.conf
	sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://cinder:Password123!@'$CONTROLLERNAME'/cinder' /etc/cinder/cinder.conf
	sed -i '/transport_url = */c\transport_url = rabbit://cinder:Password123!@'$CONTROLLERNAME  /etc/cinder/cinder.conf
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/cinder/cinder.conf
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/cinder/cinder.conf
	sed -i '/enabled_backends=*/c\enabled_backends='$CINDERBACKENDS /etc/cinder/cinder.conf

if [[ $CINDERBACKENDS == *"scaleio"* ]]
	then
		echo "
[scaleio]
san_ip = $SIO_GW
sio_protection_domain_name = $SIO_PD
sio_storage_pool_name = $SIO_SP
sio_storage_pools = $SIO_PD:$SIO_SP
san_login = admin
san_password = Password123!
san_thin_provision = true
volume_driver=cinder.volume.drivers.emc.scaleio.ScaleIODriver
volume_backend_name=scaleio
	" >> /etc/cinder/cinder.conf
		sed -i '/default_volume_type=*/c\default_volume_type=ScaleIO_Thin' /etc/cinder/cinder.conf
		printf " --> SUCCESSFUL - Added ScaleIO Config \n"
	else
		sed -i '/default_volume_type=*/c\default_volume_type=Unity_iSCSI_Thin' /etc/cinder/cinder.conf
fi

### Deactivated because currently no supported unity driver for cinder in newton release
<<Deactivated
	if [[ $CINDERBACKENDS == *"unity"* ]]
		then
			echo "
[unity]
storage_protocol = iSCSI
storage_pool_names = $UNITY_POOL
san_ip = $UNITY_IP
san_login = Local/admin
san_password = Password123!
volume_driver = cinder.volume.drivers.emc.emc_unity.EMCUnityDriver
volume_backend_name = unity
" >> /etc/cinder/cinder.conf
			printf " --> SUCCESSFUL - Added Unity Config \n"
			if (curl -o /usr/lib/python2.7/dist-packages/cinder/volume/drivers/emc/emc_unity.py https://raw.githubusercontent.com/emc-openstack/unity-cinder-driver/mitaka/emc_unity.py ) >> $LOGFILE 2>&1
				then printf " --> SUCCESSFUL - Got Unity Driver \n"; else printf " --> ERROR - could not get Unity Driver - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	fi
Deactivated

	if ( su -s /bin/sh -c "cinder-manage db sync" cinder) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated Cinder Database\n"; else printf " --> ERROR - could not populated Cinder Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service nova-api restart)  >> $LOGFILE 2>&1; 			then printf " --> SUCCESSFUL - restarted nova-api service \n"; else printf " --> ERROR - could not restart nova-api service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service cinder-api restart)  >> $LOGFILE 2>&1; 			then printf " --> SUCCESSFUL - restarted cinder-api service \n"; else printf " --> ERROR - could not restart cinder-api service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service cinder-scheduler restart)  >> $LOGFILE 2>&1;	then printf " --> SUCCESSFUL - restarted cinder-scheduler service \n"; else printf " --> ERROR - could not restart cinder-scheduler service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service cinder-volume restart)  >> $LOGFILE 2>&1;	then printf " --> SUCCESSFUL - restarted cinder-volume service \n"; else printf " --> ERROR - could not restart cinder-volume service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	rm -f /var/lib/cinder/cinder.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"
	
printf "
  -----------------------------------------
 | #### Finished Cinder Installation ##### |
  -----------------------------------------\n\n" | tee -a $LOGFILE
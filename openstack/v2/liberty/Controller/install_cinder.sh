#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
CONTROLLERIP=$3
SIO_GW=$4
SIO_PD=$5
SIO_SP=$6
CONFIGPATH=$7

printf "
  --------------------------------------
 | #### Start Cinder Installation ##### |
  --------------------------------------\n\n"	 | tee -a $LOGFILE
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install cinder-api cinder-scheduler python-cinderclient cinder-volume -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Cinder Packages\n"; else printf " --> ERROR - could not install Cinder Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
	if (cp ${CONFIGPATH}/configs/cinder.conf /etc/cinder/cinder.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied cinder.conf file \n"; else printf " --> ERROR - Could not copy cinder.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	
	
printf " ### Configure Cinder \n" | tee -a $LOGFILE	
	if (echo "[cinder]
os_region_name = RegionOne" >> /etc/nova/nova.conf); then printf " --> SUCCESSFUL - Added Cinder to Nova Config\n"; else printf " --> ERROR - could not  add Cinder to Nova Config- Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	sed -i '/my_ip = */c\my_ip = '$CONTROLLERIP /etc/cinder/cinder.conf
	sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://cinder:Password123!@'$CONTROLLERNAME'/cinder' /etc/cinder/cinder.conf
	sed -i '/rabbit_host = */c\rabbit_host = '$CONTROLLERNAME /etc/cinder/cinder.conf
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/cinder/cinder.conf
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/cinder/cinder.conf
	sed -i '/san_ip = */c\san_ip = '$SIO_GW /etc/cinder/cinder.conf
	sed -i '/sio_protection_domain_name = */c\sio_protection_domain_name = '$SIO_PD /etc/cinder/cinder.conf
	sed -i '/sio_storage_pool_name =*/c\sio_storage_pool_name = '$SIO_SP /etc/cinder/cinder.conf
	sed -i '/sio_storage_pools = */c\sio_storage_pools = '$SIO_PD':'$SIO_SP /etc/cinder/cinder.conf
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
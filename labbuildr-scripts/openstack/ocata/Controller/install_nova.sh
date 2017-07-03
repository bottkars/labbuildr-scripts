#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
CONTROLLERIP=$3
INSTALLPATH=$4

printf "
  ------------------------------------
 | #### Started Nova Installation ##### |
  ------------------------------------\n\n" | tee -a $LOGFILE
 
 printf " ### Install Packages\n" | tee -a $LOGFILE
 if (apt-get install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler nova-placement-api -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Installed Nova Packages\n"; else printf " --> ERROR - could not install Nova Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
 
printf " ### Configure Nova \n"

	if (cp ${INSTALLPATH}/configs/nova.conf /etc/nova/nova.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied nova.conf file \n"; else printf " --> ERROR - Could not copy nova.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	
	sed -i '/my_ip = x.x.x.x/c\my_ip = '$CONTROLLERIP /etc/nova/nova.conf
	sed -i '/memcached_servers= */c\memcached_servers = '$CONTROLLERNAME':11211' /etc/nova/nova.conf
	sed -i '/connection = nova_api/c\connection = mysql+pymysql://nova:Password123!@'$CONTROLLERNAME'/nova_api' /etc/nova/nova.conf
	sed -i '/connection = nova_db/c\connection = mysql+pymysql://nova:Password123!@'$CONTROLLERNAME'/nova' /etc/nova/nova.conf
	sed -i '/transport_url = */c\transport_url = rabbit://nova_ctrl:Password123!@'$CONTROLLERNAME  /etc/nova/nova.conf
	sed -i '/auth_uri = nova_uri/c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/nova/nova.conf
	sed -i '/auth_url = nova_url/c\auth_url = http://'$CONTROLLERNAME':35357' /etc/nova/nova.conf
	sed -i '/api_servers = */c\api_servers = http://'$CONTROLLERNAME':9292' /etc/nova/nova.conf
	sed -i '/auth_url = placement/c\auth_url = http://'$CONTROLLERNAME':35357' /etc/nova/nova.conf
	
if (su -s /bin/sh -c "nova-manage api_db sync" nova) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated nova_api Database\n"; else printf " --> ERROR - could not populated nova_api Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Registered cell0 Database\n"; else printf " --> ERROR - could not registere cell0  Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1" nova) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created cell1 \n"; else printf " --> ERROR - could not create cell1 - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (su -s /bin/sh -c "nova-manage db sync" nova) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated nova Database\n"; else printf " --> ERROR - could not populated nova Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
if (service nova-api restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-api service \n"; else printf " --> ERROR - could not restart nova-api service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (service nova-consoleauth restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-consoleauth service \n"; else printf " --> ERROR - could not restart nova-consoleauth service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (service nova-scheduler restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-scheduler service \n"; else printf " --> ERROR - could not restart nova-scheduler service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (service nova-conductor restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-conductor service \n"; else printf " --> ERROR - could not restart nova-conductor service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (service nova-novncproxy restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-novncproxy service \n"; else printf " --> ERROR - could not restart nova-novncproxy service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

rm -f /var/lib/nova/nova.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"

printf "
  ---------------------------------------
 | #### Finished Nova Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE

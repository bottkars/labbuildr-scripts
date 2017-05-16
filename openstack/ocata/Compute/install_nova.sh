#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
LOCALIP=$3
INSTALLPATH=$4

printf "
  ------------------------------------
 | #### Start Nova Installation ##### |
  ------------------------------------\n\n" | tee -a $LOGFILE
 
printf " ### Install Packages\n" | tee -a $LOGFILE
if (apt-get install nova-compute -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Nova Packages\n"; else printf " --> ERROR - could not install Nova Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
 
printf " ### Configure Nova \n"

	if (cp ${INSTALLPATH}/configs/nova.conf /etc/nova/nova.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied nova.conf file \n"; else printf " --> ERROR - Could not copy nova.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	
	sed -i '/my_ip = x.x.x.x/c\my_ip = '$LOCALIP /etc/nova/nova.conf
	sed -i '/memcached_servers = */c\memcached_servers = '$CONTROLLERNAME':11211' /etc/nova/nova.conf
	sed -i '/transport_url = */c\transport_url = rabbit://nova_compute:Password123!@'$CONTROLLERNAME  /etc/nova/nova.conf
	sed -i '/auth_uri = nova_uri/c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/nova/nova.conf
	sed -i '/auth_url = nova_url/c\auth_url = http://'$CONTROLLERNAME':35357' /etc/nova/nova.conf
	sed -i '/api_servers = */c\api_servers = http://'$CONTROLLERNAME':9292' /etc/nova/nova.conf
	sed -i '/novncproxy_base_url = /c\novncproxy_base_url =http://'$CONTROLLERNAME':6080/vnc_auto.html' /etc/nova/nova.conf

	if (service nova-compute restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-compute service \n"; else printf " --> ERROR - could not restart nova-compute service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	rm -f /var/lib/nova/nova.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"

printf "
  ---------------------------------------
 | #### Finished Nova Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE
  
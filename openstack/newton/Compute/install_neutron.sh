#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
LOCALIP=$3
INSTALLPATH=$4

printf "
  ------------------------------------------
 | #### Finished Neutron Installation ##### |
  ------------------------------------------\n\n" | tee -a $LOGFILE
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install neutron-plugin-linuxbridge-agent -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Neutron Packages\n"; else printf " --> ERROR - could not install Neutron Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Configure Neutron \n" | tee -a $LOGFILE
	if (cp ${INSTALLPATH}/configs/neutron.conf /etc/neutron/neutron.conf) >> $LOGFILE 2>&1; 											then printf " --> SUCCESSFUL - Copied neutron.conf file \n"; else printf " --> ERROR - Could not copy neutron.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${INSTALLPATH}/configs/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL - Copied linuxbridge_agent.inifile \n"; else printf " --> ERROR - Could not copy linuxbridge_agent.ini file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	sed -i '/transport_url = rabbit*/c\transport_url = rabbit://neutron:Password123!@'$CONTROLLERNAME /etc/neutron/neutron.conf
	sed -i '/memcached_servers = */c\memcached_servers = '$CONTROLLERNAME':11211' /etc/neutron/neutron.conf
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/neutron/neutron.conf
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/neutron/neutron.conf
	sed -i '/local_ip = */c\local_ip = '$LOCALIP /etc/neutron/plugins/ml2/linuxbridge_agent.ini
	
	if (echo "
[neutron]
url = http://$CONTROLLERNAME:9696
auth_url = http://$CONTROLLERNAME:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = Password123!
	" >> /etc/nova/nova.conf); then printf " --> SUCCESSFUL - added neutron config to nova.config\n"; else printf " --> ERROR - could not add  neutron config to nova.config - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
	if (service nova-compute restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-compute service \n"; else printf " --> ERROR - could not restart nova-compute service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service neutron-linuxbridge-agent restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted neutron-linuxbridge-agent service \n"; else printf " --> ERROR - could not restart neutron-linuxbridge-agent service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf "
  ---------------------------------------
 | #### Start Neutron Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE
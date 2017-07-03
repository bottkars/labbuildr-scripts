#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
LOCALIP=$3
INSTALLPATH=$4

printf "
  ------------------------------------------
 | #### Start Neutron Installation ##### |
  ------------------------------------------\n\n" | tee -a $LOGFILE
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install neutron-plugin-linuxbridge-agent sshpass -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Neutron Packages\n"; else printf " --> ERROR - could not install Neutron Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Configure Neutron \n" | tee -a $LOGFILE
	if (cp ${INSTALLPATH}/configs/neutron.conf /etc/neutron/neutron.conf) >> $LOGFILE 2>&1; 											then printf " --> SUCCESSFUL - Copied neutron.conf file \n"; else printf " --> ERROR - Could not copy neutron.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${INSTALLPATH}/configs/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL - Copied linuxbridge_agent.inifile \n"; else printf " --> ERROR - Could not copy linuxbridge_agent.ini file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	
	#neutron.conf
	sed -i '/transport_url = rabbit*/c\transport_url = rabbit://neutron:Password123!@'$CONTROLLERNAME /etc/neutron/neutron.conf
	sed -i '/memcached_servers = */c\memcached_servers = '$CONTROLLERNAME':11211' /etc/neutron/neutron.conf
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/neutron/neutron.conf
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/neutron/neutron.conf
	sed -i '/local_ip = */c\local_ip = '$LOCALIP /etc/neutron/plugins/ml2/linuxbridge_agent.ini
	
	#nova.conf
	sed -i '/url = neutron_api/c\url = http://'$CONTROLLERNAME':9696' /etc/nova/nova.conf
	sed -i '/auth_url = auth_neutron/c\auth_url = http://'$CONTROLLERNAME':35357' /etc/nova/nova.conf
	
	if (service nova-compute restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-compute service \n"; else printf " --> ERROR - could not restart nova-compute service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service neutron-linuxbridge-agent restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted neutron-linuxbridge-agent service \n"; else printf " --> ERROR - could not restart neutron-linuxbridge-agent service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Discover Compute Nodes on Controller \n"
	if (ssh-keyscan -H $CONTROLLERNAME >> ~/.ssh/known_hosts)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Added $CONTROLLERNAME SSH Key to ~/.ssh/known_hosts \n"; else printf " --> ERROR - could not add $CONTROLLERNAME SSH Key to ~/.ssh/known_hosts \n" | tee -a $LOGFILE; fi
	if (sshpass -p 'Password123!' ssh root@$CONTROLLERNAME 'su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova')  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Discovered Compute Nodes on $CONTROLLERNAME \n";  else printf " --> ERROR - could not discover Compute Nodes on $CONTROLLERNAME \n" | tee -a $LOGFILE; fi
	if (sshpass -p 'Password123!' ssh root@$CONTROLLERNAME 'su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova')  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Discovered Compute Nodes on $CONTROLLERNAME \n";  else printf " --> ERROR - could not discover Compute Nodes on $CONTROLLERNAME \n" | tee -a $LOGFILE; fi
	
printf "
  ---------------------------------------
 | #### Finished Neutron Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE
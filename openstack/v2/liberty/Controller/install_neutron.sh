#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
CONTROLLERIP=$3
BUILDDOMAIN=$4
DOMAINSUFFIX=$5
CONFIGPATH=$6

printf "
  ------------------------------------------
 | #### Finished Neutron Installation ##### |
  ------------------------------------------\n\n" | tee -a $LOGFILE
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install neutron-server neutron-plugin-ml2 neutron-plugin-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent python-neutronclient -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Neutron Packages\n"; else printf " --> ERROR - could not install Neutron Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Configure Neutron \n" | tee -a $LOGFILE
	if (cp ${CONFIGPATH}/configs/neutron.conf /etc/neutron/neutron.conf) >> $LOGFILE 2>&1; 											then printf " --> SUCCESSFUL - Copied neutron.conf file \n"; else printf " --> ERROR - Could not copy neutron.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${CONFIGPATH}/configs/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini) >> $LOGFILE 2>&1; 							then printf " --> SUCCESSFUL - Copied ml2_conf.ini file \n"; else printf " --> ERROR - Could not copy ml2_conf.ini file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${CONFIGPATH}/configs/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL - Copied linuxbridge_agent.inifile \n"; else printf " --> ERROR - Could not copy linuxbridge_agent.ini file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${CONFIGPATH}/configs/l3_agent.ini /etc/neutron/l3_agent.ini) >> $LOGFILE 2>&1; 												then printf " --> SUCCESSFUL - Copied l3_agent.ini file \n"; else printf " --> ERROR - Could not copy l3_agent.ini file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${CONFIGPATH}/configs/dhcp_agent.ini /etc/neutron/dhcp_agent.ini) >> $LOGFILE 2>&1; 										then printf " --> SUCCESSFUL - Copied dhcp_agent.ini file \n"; else printf " --> ERROR - Could not copy dhcp_agent.ini file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${CONFIGPATH}/configs/dnsmasq-neutron.conf /etc/neutron/dnsmasq-neutron.conf) >> $LOGFILE 2>&1; 			then printf " --> SUCCESSFUL - Copied dnsmasq-neutron.conf file \n"; else printf " --> ERROR - Could not copy dnsmasq-neutron.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${CONFIGPATH}/configs/metadata_agent.ini /etc/neutron/metadata_agent.ini) >> $LOGFILE 2>&1; 						then printf " --> SUCCESSFUL - Copied metadata_agent.ini file \n"; else printf " --> ERROR - Could not copy metadata_agent.ini file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 

	sed -i '/nova_url = */c\nova_url = http://'$CONTROLLERNAME':8774/v2' /etc/neutron/neutron.conf
	sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://neutron:Password123!@'$CONTROLLERNAME'/neutron' /etc/neutron/neutron.conf
	sed -i '/rabbit_host = */c\rabbit_host = '$CONTROLLERNAME /etc/neutron/neutron.conf
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/neutron/neutron.conf
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/neutron/neutron.conf
	sed -i '/local_ip = */c\local_ip = '$CONTROLLERIP /etc/neutron/plugins/ml2/linuxbridge_agent.ini
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/neutron/metadata_agent.ini
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/neutron/metadata_agent.ini
	sed -i '/nova_metadata_ip = */c\nova_metadata_ip = '$CONTROLLERIP /etc/neutron/metadata_agent.ini
	sed -i '/dhcp_domain = */c\dhcp_domain = '$BUILDDOMAIN'.'$DOMAINSUFFIX /etc/neutron/dhcp_agent.ini
	
if (echo "
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
service_metadata_proxy = True
metadata_proxy_shared_secret = Password123!
" >> /etc/nova/nova.conf); then printf " --> SUCCESSFUL - added neutron config to nova.config\n"; else printf " --> ERROR - could not add  neutron config to nova.config - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

	if (su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated Neutron Database\n"; else printf " --> ERROR - could not populated Neutron Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

	if (service nova-api restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-api service \n"; else printf " --> ERROR - could not restart nova-api service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service neutron-server restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted neutron-server service \n"; else printf " --> ERROR - could not restart neutron-server service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service neutron-plugin-linuxbridge-agent restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted neutron-plugin-linuxbridge-agent service \n"; else printf " --> ERROR - could not restart neutron-plugin-linuxbridge-agent service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service neutron-dhcp-agent restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted neutron-dhcp-agent restart service \n"; else printf " --> ERROR - could not restart neutron-dhcp-agent restart service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service neutron-metadata-agent restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted  neutron-metadata-agent service \n"; else printf " --> ERROR - could not restart  neutron-metadata-agent service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service neutron-l3-agent restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted neutron-l3-agent service \n"; else printf " --> ERROR - could not restart neutron-l3-agent service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	rm -f /var/lib/neutron/neutron.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"


printf "
  ------------------------------------------
 | #### Finished Neutron Installation ##### |
  ------------------------------------------\n\n" | tee -a $LOGFILE


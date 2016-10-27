#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
CONFIGPATH=$3
HEATDOMAINID=$(openstack --os-project-domain-id default --os-user-domain-id default --os-project-name admin --os-username admin --os-password Password123! --os-auth-url http://$CONTROLLERNAME:35357/v3 domain list | grep -i heat | awk '{print $2}')

printf "
  ------------------------------------
 | #### Start Heat Installation ##### |
  ------------------------------------\n\n" | tee -a $LOGFILE

printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install heat-api heat-api-cfn heat-engine python-heatclient -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Heat Packages\n"; else printf " --> ERROR - could not install Heat Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi


printf " ### Configure Heat\n" | tee -a $LOGFILE
	if (cp ${CONFIGPATH}/configs/heat.conf /etc/heat/heat.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - copied heat.conf \n"; else printf " --> ERROR - could not copy heat.conf  - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://heat:Password123!@'$CONTROLLERNAME'/heat' /etc/heat/heat.conf
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/heat/heat.conf
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/heat/heat.conf
	sed -i '/rabbit_host = */c\rabbit_host = '$CONTROLLERNAME	/etc/heat/heat.conf
	sed -i '/stack_user_domain = */c\stack_user_domain = '$HEATDOMAINID /etc/heat/heat.conf
	sed -i '/OPENSTACK_HOST = */c\OPENSTACK_HOST = \"'$CONTROLLERNAME'\"'  /etc/openstack-dashboard/local_settings.py
	if ( su -s /bin/sh -c "heat-manage db_sync" heat) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated Heat Database\n"; else printf " --> ERROR - could not populated Heat Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
	
	if (service heat-api restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted heat-api service \n"; else printf " --> ERROR - could not restart heat-api service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service heat-api-cfn restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted heat-api-cfn service \n"; else printf " --> ERROR - could not restart heat-api-cfn service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service heat-engine restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted heat-engine service \n"; else printf " --> ERROR - could not restart heat-engine service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	rm -f /var/lib/heat/heat.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"
	
printf "
  ---------------------------------------
 | #### Finished Heat Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE 
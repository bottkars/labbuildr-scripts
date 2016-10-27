#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
CONFIGPATH=$3

printf "
  -----------------------------------------
 | #### Finished Glance Installation ##### |
  -----------------------------------------\n\n" | tee -a $LOGFILE
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install glance python-glanceclient -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Glance Packages\n"; else printf " --> ERROR - could not install Glance Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Configure Glance \n" | tee -a $LOGFILE
	if (cp ${CONFIGPATH}/configs/glance-api.conf /etc/glance/glance-api.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied glance-api.conf file \n"; else printf " --> ERROR - Could not copy glance-api.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${CONFIGPATH}/configs/glance-registry.conf /etc/glance/glance-registry.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied glance-registry.conf file \n"; else printf " --> ERROR - Could not copy glance-registry.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	
	#Configure Glance-Api
	sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://glance:Password123!@'$CONTROLLERNAME'/glance' /etc/glance/glance-api.conf | tee -a $LOGFILE 2>&1
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000'  /etc/glance/glance-api.conf | tee -a $LOGFILE 2>&1
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357'  /etc/glance/glance-api.conf | tee -a $LOGFILE 2>&1

	#Configure Glance-Registry
	sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://glance:Password123!@'$CONTROLLERNAME'/glance' /etc/glance/glance-registry.conf | tee -a $LOGFILE 2>&1
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000'  /etc/glance/glance-registry.conf | tee -a $LOGFILE 2>&1
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357'  /etc/glance/glance-registry.conf | tee -a $LOGFILE 2>&1
	
	if (su -s /bin/sh -c "glance-manage db_sync" glance) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated Glance Database\n"; else printf " --> ERROR - could not populated Glance Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service glance-api restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted glance-api service \n"; else printf " --> ERROR - could not restart glance-api service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service glance-registry restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted glance-registry service \n"; else printf " --> ERROR - could not restart glance-registry service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	rm -f /var/lib/glance/glance.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"
	
printf "
  -----------------------------------------
 | #### Finished Glance Installation ##### |
  -----------------------------------------\n\n" | tee -a $LOGFILE	
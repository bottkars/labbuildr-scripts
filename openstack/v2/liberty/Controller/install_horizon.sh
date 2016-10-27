#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
CONFIGPATH=$3

printf "
  ---------------------------------------
 | #### Start Horizon Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE

printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install openstack-dashboard -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Horizon Packages\n"; else printf " --> ERROR - could not install Horizon Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi


printf " ### Configure Horizon\n" | tee -a $LOGFILE
	if (apt-get remove --auto-remove openstack-dashboard-ubuntu-theme -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Removed Ubuntu Dashboard Theme \n"; else printf " --> ERROR - could not removed Ubuntu Dashboard Theme - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (cp ${CONFIGPATH}/configs/local_settings.py /etc/openstack-dashboard/local_settings.py) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - copied local_settings.py \n"; else printf " --> ERROR - could not copy local_settings.py  - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (cp ${CONFIGPATH}/configs/logo-splash.png /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo-splash.png) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Took over Identity \n"; else printf " --> ERROR - could not copy logo-splash.png  - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	sed -i '/OPENSTACK_HOST = */c\OPENSTACK_HOST = \"'$CONTROLLERNAME'\"'  /etc/openstack-dashboard/local_settings.py
	if (service apache2 restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted apache2 service \n"; else printf " --> ERROR - could not restart apache2 service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
printf "
  ------------------------------------------
 | #### Finished Horizon Installation ##### |
  ------------------------------------------\n\n" | tee -a $LOGFILE 
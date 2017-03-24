#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
INSTALLPATH=$3
AUTHURL="http://$CONTROLLERNAME:35357/v3"

MURANOBASECOMMAND="murano --os-region-name RegionOne --os-project-name admin --os-username admin --os-password Password123! --os-auth-url $AUTHURL"

printf "
  ---------------------------------------------
 | #### Start Murano Core Installation ##### |
  ---------------------------------------------\n\n" | tee -a $LOGFILE
 
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	### Suppressing User Interactions during Package installation
	export DEBIAN_FRONTEND=noninteractive 
	if (apt-get install murano-api murano-engine python-muranoclient -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Installed Murano Core Packages\n"; else printf " --> ERROR - could not install Murano Core Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
  

  
  
printf " ### Configure Murano \n" | tee -a $LOGFILE
	if (cp ${INSTALLPATH}/configs/murano/murano.conf /etc/murano/murano.conf) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL - Copied murano.conf file \n"; else printf " --> ERROR - Could not copy murano.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	
	
	
	sed -i '/transport_url = controller*/c\transport_url = rabbit://neutron:Password123!@'$CONTROLLERNAME /etc/murano/murano.conf
	sed -i '/memcached_servers = */c\memcached_servers = '$CONTROLLERNAME':11211' /etc/murano/murano.conf
	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/murano/murano.conf
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/murano/murano.conf
	sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://murano:Password123!@'$CONTROLLERNAME'/murano' /etc/murano/murano.conf
 

if (echo "
[keystone_authtoken]
memcached_servers = $CONTROLLERNAME:11211
auth_version = v3
auth_url = http://$CONTROLLERNAME:35357
auth_uri = http://$CONTROLLERNAME:5000/v3
project_domain_id = default
project_name = service
user_domain_id = default
auth_type = password
username = murano
password = Password123!

[engine]
enable_model_policy_enforcer = False

[murano]
url = http://$CONTROLLERNAME:8082

[networking]
create_router = true
external_network = Internet

[oslo_concurrency]
lock_path = /var/lib/murano/tmp

" >> /etc/murano/murano.conf); then printf " --> SUCCESSFUL - added Config Sections to murano.config\n"; else printf " --> ERROR - could not add Config Sections to murano.config - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 

if ($ADMINBASECOMMAND murano-db-manage upgrade) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated Murano Database\n"; else printf " --> ERROR - could not populated Murano Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi  

printf " ### Restart Services \n" | tee -a $LOGFILE
	if (service murano-api restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted murano-api service \n"; else printf " --> ERROR - could not restart murano-api service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service murano-engine restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted murano-engine service \n"; else printf " --> ERROR - could not restart murano-engine service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if ($MURANOBASECOMMAND package-import --is-public ${INSTALLPATH}/configs/murano/io.murano.zip) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Imported Murano Core Libary"; else printf " --> ERROR - Could not import Murano Core Libary - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	
printf "
  --------------------------------------------
 | #### Finished Murano Core Installation ##### |
  --------------------------------------------\n\n" | tee -a $LOGFILE
 
 printf "
  ---------------------------------------------
 | #### Start Murano GUI Installation ##### |
  ---------------------------------------------\n\n" | tee -a $LOGFILE
 
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install python-murano-dashboard -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Installed Murano GUI Packages\n"; else printf " --> ERROR - could not install Murano GUI Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
 
  
  
printf " ### Configure Murano GUI \n" | tee -a $LOGFILE
	## WOrkaround Bug, missing templates
	if (mkdir /usr/lib/python2.7/dist-packages/muranodashboard/templates)>> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created Template Directory "; else printf " --> ERROR - Could not create Template Directory - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (tar -xvf ${INSTALLPATH}/configs/murano/murano_templates.tar -C /usr/lib/python2.7/dist-packages/muranodashboard/templates) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Unzipped Internal Templates to Murano Directory"; else printf " --> ERROR - could not unzipped Internal Templates to Murano Directory - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (python /usr/share/openstack-dashboard/manage.py collectstatic --noinput) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Run collectstatics"; else printf " --> ERROR - On running Collectstatics - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (python /usr/share/openstack-dashboard/manage.py compress) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Compressed Files"; else printf " --> ERROR - On compressing Files - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	## To Workaround Bug http://git.openstack.org/cgit/openstack/murano-dashboard/commit/?id=410c869242e21fcb09bc692d704cd8dec266fa32
	## change image api version for horizon to 1
	sed -i 's/"image": 2,/"image": 1,/g' /etc/openstack-dashboard/local_settings.py

printf " ### Restart Services \n" | tee -a $LOGFILE
	if (service apache2 restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted apache2 service \n"; else printf " --> ERROR - could not restart apache2 service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
  
printf "
  ---------------------------------------------
 | #### Finished Murano GUI Installation ##### |
  ---------------------------------------------\n\n" | tee -a $LOGFILE

  
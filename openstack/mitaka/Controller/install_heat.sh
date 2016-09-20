#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
AUTHURL="http://$(hostname):35357/v3"
HEATDOMAINID=$(openstack --os-username admin --os-password Password123! --os-project-name admin --os-domain-name default --os-identity-api-version 3 --os-auth-url $AUTHURL domain list | grep -i heat | awk '{print $2}')
DEFAULTDOMAINID=$(openstack --os-username admin --os-password Password123! --os-project-name admin --os-domain-name default --os-identity-api-version 3 --os-auth-url $AUTHURL domain list | grep -i default | awk '{print $2}')
 
printf "\n\n #### Start Heat Installation \n"


printf " ############# DEFAULTDOMAINID: $DEFAULTDOMAINID \n"
### Install
	printf " ### Install Packages "
		if apt-get install heat-api heat-api-cfn heat-engine python-heatclient -y >> /tmp/os_logs/heat.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " ERROR --> Could not install Heat Packages - see /tmp/os_logs/heat.log"
		fi				

#Copy Predefined Configs
	printf " ### Configure Heat "
		cp ./configs/heat.conf /etc/heat/heat.conf
			
		sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://heat:Password123!@'$LOCALHOSTNAME'/heat' /etc/heat/heat.conf
		sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000' /etc/heat/heat.conf
		sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357' /etc/heat/heat.conf
		sed -i '/rabbit_host = */c\rabbit_host = '$LOCALHOSTNAME	/etc/heat/heat.conf
		#sed -i '/stack_user_domain = */c\stack_user_domain = '$HEATDOMAINID /etc/heat/heat.conf
		sed -i '/project_domain_id = */c\project_domain_id = '$DEFAULTDOMAINID	/etc/heat/heat.conf
		sed -i '/user_domain_id = */c\user_domain_id = '$DEFAULTDOMAINID	/etc/heat/heat.conf
		sed -i '/heat_metadata_server_url = */c\heat_metadata_server_url = http://'$LOCALHOSTNAME':8000' /etc/heat/heat.conf
		sed -i '/heat_waitcondition_server_url = */c\heat_waitcondition_server_url = http://'$LOCALHOSTNAME':8000/v1/waitcondition' /etc/heat/heat.conf
		printf $green " --> done"
 
printf " ### Populate Heat Database"
		if su -s /bin/sh -c "heat-manage db_sync" heat >> /tmp/os_logs/heat.log 2>&1 >> /tmp/os_logs/heat.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " ERROR --> Could not populate Heat Database - see /tmp/os_logs/heat.log"		
		fi
		
### Restart Glance-Api
printf " ### Restart Glance Services \n"
	if service heat-api restart >> /tmp/os_logs/glance.log 2>&1; 		then printf $green " --> Restart Heat-Api done"; 			else printf $red " ERROR --> Could not restart Heat-Api Service - see /tmp/os_logs/heat.log"; fi
	if service heat-api-cfn restart >> /tmp/os_logs/glance.log 2>&1; then printf $green " --> Restart Heat-api-cfn done"; 	else printf $red " ERROR --> Could not restart Heat-api-cfn - see /tmp/os_logs/heat.log"; fi		
	if service heat-engine restart >> /tmp/os_logs/glance.log 2>&1; then printf $green " --> Restart Heat-engine  done"; 	else printf $red " ERROR --> Could not restart Heat-engine  Service - see /tmp/os_logs/heat.log"; fi		
	
	#Remove glance dummy database
	printf " ### Remove Heat Dummy Database"
		rm -f /var/lib/heat/heat.sqlite
	printf $green " --> done"





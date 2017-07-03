#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALHOSTIP=$2

printf "\n\n #### Start Horizon Installation \n"

### Install
	printf " ### Install Packages "
		if apt-get install openstack-dashboard -y >> /tmp/os_logs/horizon.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not install Horizon Packages - see /tmp/os_logs/horizon.log"
		fi		
## Remove ubuntu theme (because of bugs)
	printf " ### Remove  openstack-dashboard-ubuntu-theme"
		if apt-get remove --auto-remove openstack-dashboard-ubuntu-theme -y >> /tmp/os_logs/horizon.log 2>&1; then 
				printf $green " --> done"
		else
			printf $red " --> Could not remove  openstack-dashboard-ubuntu-theme - see /tmp/os_logs/horizon.log"
		fi		
		
#Copy predefined Config
		printf " ### Configure Horizon \n"
			cp ./configs/local_settings.py /etc/openstack-dashboard/local_settings.py
#Configure
			sed -i '/OPENSTACK_HOST = */c\OPENSTACK_HOST = \"'$LOCALHOSTNAME'\"'  /etc/openstack-dashboard/local_settings.py
	printf $green " --> done\n"

# Replace Splash Logo
	printf " ## Taking over Identity ..."
	cp ./configs/logo-splash.png /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo-splash.png
	printf " --> done."
	
#Restart Service
	printf " ### Restart Apache2 Service"
		if service apache2 restart >> /tmp/os_logs/horizon.log 2>&1; then printf " --> done\n"; else printf  " --> Could not restart  Apache2 Service - see /tmp/os_logs/horizon.log\n"; fi 
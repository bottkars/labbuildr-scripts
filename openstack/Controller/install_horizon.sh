#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALHOSTIP=$2

printf "$green" '############################
###### Install Horizon #####
#############################'
printf '\n'

### Install
apt-get install openstack-dashboard -y >> ./logs/horizon.log 2>&1
## Remove ubuntu theme (because of bugs)
apt-get remove --auto-remove openstack-dashboard-ubuntu-theme -y >> ./logs/horizon.log 2>&1

#Copy predefined Config
cp ./configs/local_settings.py /etc/openstack-dashboard/local_settings.py

#Configure
sed -i '/OPENSTACK_HOST = */c\OPENSTACK_HOST = \"'$LOCALHOSTNAME'\"'  /etc/openstack-dashboard/local_settings.py

#Restart Service
service apache2 restart >> ./logs/horizon.log 2>&1
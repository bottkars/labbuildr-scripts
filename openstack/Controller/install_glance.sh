#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1

printf "$green" '############################
###### Install Glance #####
#############################'
printf '\n'

### Install
apt-get install glance python-glanceclient -y >> ./logs/glance.log 2>&1

#Copy Predefined Configs
cp ./configs/glance-api.conf /etc/glance/glance-api.conf
cp ./configs/glance-registry.conf /etc/glance/glance-registry.conf

#Configure Glance-Api
sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://glance:Password123!@'$LOCALHOSTNAME'/glance' /etc/glance/glance-api.conf
sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000'  /etc/glance/glance-api.conf
sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357'  /etc/glance/glance-api.conf

#Configure Glance-Registry
sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://glance:Password123!@'$LOCALHOSTNAME'/glance' /etc/glance/glance-registry.conf
sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000'  /etc/glance/glance-registry.conf
sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357'  /etc/glance/glance-registry.conf

#Populate Database
su -s /bin/sh -c "glance-manage db_sync" glance >> ./logs/glance.log 2>&1

#Restart Services
service glance-registry restart  >> ./logs/glance.log 2>&1
service glance-api restart  >> ./logs/glance.log 2>&1
	
#Remove glance dummy database
rm -f /var/lib/glance/glance.sqlite

#Test
sleep 5
openstack --os-auth-url http://$LOCALHOSTNAME:35357/v3 --os-project-domain-id default --os-user-domain-id default --os-project-name admin --os-username admin --os-auth-type password --os-password Password123! --os-image-api-version 2 image list
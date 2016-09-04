#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALHOSTIP=$2

printf "$green" '############################
###### Install Cinder #####
#############################'
printf '\n'

### Install
apt-get install cinder-api cinder-scheduler python-cinderclient cinder-volume -y >> ./logs/cinder.log 2>&1

#Copy Predefined Configs
cp ./configs/cinder.conf /etc/cinder/cinder.conf

#Configure
echo "[cinder]
os_region_name = RegionOne" >> /etc/nova/nova.conf

sed -i '/my_ip = */c\my_ip = '$LOCALHOSTIP /etc/cinder/cinder.conf
sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://cinder:Password123!@'$LOCALHOSTNAME'/cinder' /etc/cinder/cinder.conf
sed -i '/rabbit_host = */c\rabbit_host = '$LOCALHOSTNAME /etc/cinder/cinder.conf
sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000' /etc/cinder/cinder.conf
sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357' /etc/cinder/cinder.conf
sed -i '/san_ip = */c\san_ip = '$LOCALHOSTNAME /etc/cinder/cinder.conf


#Populate Database
su -s /bin/sh -c "cinder-manage db sync" cinder >> ./logs/cinder.log 2>&1

#Restart Services
service nova-api restart >> ./logs/nova.log 2>&1
service cinder-api restart >> ./logs/cinder.log 2>&1
service cinder-scheduler restart >> ./logs/cinder.log 2>&1
service cinder-volume restart >> ./logs/cinder.log 2>&1

##Remove cinder dummy database
rm -f /var/lib/cinder/cinder.sqlite
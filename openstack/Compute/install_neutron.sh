#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALIP=$1
CONTROLLERIP=$2
CONTROLLERNAME=$3

printf "$green" '############################
###### Install Neutron #####
#############################'
printf '\n'

### Install
apt-get install neutron-plugin-linuxbridge-agent conntrack -y >> ./logs/neutron.log 2>&1

#Copy Predefined Configs
cp ./configs/neutron.conf /etc/neutron/neutron.conf
cp ./configs/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini

#Configure Neutron Configs
sed -i '/rabbit_host = */c\rabbit_host = '$CONTROLLERNAME /etc/neutron/neutron.conf
sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERIP':5000' /etc/neutron/neutron.conf
sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/neutron/neutron.conf
sed -i '/local_ip = */c\local_ip = '$LOCALIP /etc/neutron/plugins/ml2/linuxbridge_agent.ini

#Add neutron section to nova.conf
echo "
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
" >> /etc/nova/nova.conf

#Restart Services
service nova-compute restart >> ./logs/neutron.log 2>&1
service neutron-plugin-linuxbridge-agent restart >> ./logs/neutron.log 2>&1


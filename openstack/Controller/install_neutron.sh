#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALIP=$2

printf "$green" '############################
###### Install Neutron #####
#############################'
printf '\n'

### Install
apt-get install neutron-server neutron-plugin-ml2 neutron-plugin-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent python-neutronclient -y >> ./logs/neutron.log 2>&1

#Copy Predefined Configs
cp ./configs/neutron.conf /etc/neutron/neutron.conf
cp ./configs/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
cp ./configs/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
cp ./configs/l3_agent.ini /etc/neutron/l3_agent.ini
cp ./configs/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
cp ./configs/dnsmasq-neutron.conf /etc/neutron/dnsmasq-neutron.conf
cp ./configs/metadata_agent.ini /etc/neutron/metadata_agent.ini

#Configure Neutron Configs
sed -i '/nova_url = */c\nova_url = http://'$LOCALHOSTNAME':8774/v2' /etc/neutron/neutron.conf
sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://neutron:Password123!@'$LOCALHOSTNAME'/neutron' /etc/neutron/neutron.conf
sed -i '/rabbit_host = */c\rabbit_host = '$LOCALHOSTNAME /etc/neutron/neutron.conf
sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000' /etc/neutron/neutron.conf
sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357' /etc/neutron/neutron.conf
sed -i '/local_ip = */c\local_ip = '$LOCALIP /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i '/auth_uri = */c\auth_uri = http://'$LOCALHOSTNAME':5000' /etc/neutron/metadata_agent.ini
sed -i '/auth_url = */c\auth_url = http://'$LOCALHOSTNAME':35357' /etc/neutron/metadata_agent.ini

#Add neutron section to nova.conf
echo "
[neutron]
url = http://$LOCALHOSTNAME:9696
auth_url = http://$LOCALHOSTNAME:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
region_name = RegionOne
project_name = service
username = neutron
password = Password123!
service_metadata_proxy = True
metadata_proxy_shared_secret = Password123!
" >> /etc/nova/nova.conf

#Populate Neutron Database
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron >> ./logs/neutron.log 2>&1

#Restart Services
service nova-api restart >> ./logs/neutron.log 2>&1
service neutron-server restart >> ./logs/neutron.log 2>&1
service neutron-plugin-linuxbridge-agent restart >> ./logs/neutron.log 2>&1
service neutron-dhcp-agent restart >> ./logs/neutron.log 2>&1
service neutron-metadata-agent restart >> ./logs/neutron.log 2>&1
service neutron-l3-agent restart >> ./logs/neutron.log 2>&1

#Remove Neutron Dummy Database
rm -f /var/lib/neutron/neutron.sqlite

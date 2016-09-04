#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALIP=$2

printf "$green" '############################
###### Install Nova #####
#############################'
printf '\n'

### Install
apt-get install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient -y >> ./logs/nova.log 2>&1

# Create new Nova File
echo "[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
enabled_apis=osapi_compute,metadata
my_ip = $LOCALIP
network_api_class = nova.network.neutronv2.api.API
security_group_api = neutron
linuxnet_interface_driver = nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
verbose = True
rpc_backend = rabbit
auth_strategy = keystone
[database]
connection = mysql+pymysql://nova:Password123!@$LOCALHOSTNAME/nova
[oslo_messaging_rabbit]
rabbit_host = $LOCALHOSTNAME
rabbit_userid = nova_ctrl
rabbit_password = Password123!
[keystone_authtoken]
auth_uri = http://$LOCALHOSTNAME:5000
auth_url = http://$LOCALHOSTNAME:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = Password123!
[vnc]
vncserver_listen = \$my_ip
vncserver_proxyclient_address = \$my_ip
[glance]
host = $LOCALHOSTNAME
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
" > /etc/nova/nova.conf	

#Populate the nova database
su -s /bin/sh -c "nova-manage db sync" nova >> ./logs/nova.log 2>&1

#Restart Services
service nova-api restart >> ./logs/nova.log 2>&1
service nova-cert restart >> ./logs/nova.log 2>&1
service nova-consoleauth restart >> ./logs/nova.log 2>&1
service nova-scheduler restart >> ./logs/nova.log 2>&1
service nova-conductor restart >> ./logs/nova.log 2>&1
service nova-novncproxy restart >> ./logs/nova.log 2>&1

#Remove nova dummy database
rm -f /var/lib/nova/nova.sqlite

#Test
sleep 5
openstack --os-auth-url http://$LOCALHOSTNAME:35357/v3 --os-project-domain-id default --os-user-domain-id default --os-project-name admin --os-username admin --os-auth-type password --os-password Password123! --os-image-api-version 2 compute service list

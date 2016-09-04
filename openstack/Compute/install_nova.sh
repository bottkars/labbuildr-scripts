#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALIP=$1
CONTROLLERIP=$2
CONTROLLERNAME=$3

printf "$green" '############################
###### Install Nova #####
#############################'
printf '\n'

### Install
apt-get install nova-compute -y >> ./logs/nova.log 2>&1

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
enabled_apis=ec2,osapi_compute,metadata
rpc_backend = rabbit
auth_strategy = keystone
my_ip = $LOCALIP
network_api_class = nova.network.neutronv2.api.API
security_group_api = neutron
linuxnet_interface_driver = nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
verbose = True
[oslo_messaging_rabbit]
rabbit_host = $CONTROLLERNAME
rabbit_userid = nova_compute
rabbit_password = Password123!
[keystone_authtoken]
auth_uri = http://$CONTROLLERNAME:5000
auth_url = http://$CONTROLLERNAME:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = Password123!
[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = \$my_ip
novncproxy_base_url = http://$CONTROLLERNAME:6080/vnc_auto.html
[glance]
host = $CONTROLLERNAME
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
" > /etc/nova/nova.conf	

#Restart Services
service nova-compute restart >> ./logs/nova.log 2>&1

#Remove nova dummy database
rm -f /var/lib/nova/nova.sqlite

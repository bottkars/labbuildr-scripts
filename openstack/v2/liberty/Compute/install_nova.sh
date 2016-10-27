#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
LOCALIP=$3

printf "
  ------------------------------------
 | #### Start Nova Installation ##### |
  ------------------------------------\n\n" | tee -a $LOGFILE
 
 printf " ### Install Packages\n" | tee -a $LOGFILE
 if (apt-get install nova-compute -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Nova Packages\n"; else printf " --> ERROR - could not install Nova Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
 
printf " ### Configure Nova \n"

if (echo "[DEFAULT]
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
" > /etc/nova/nova.conf); then printf " --> SUCCESSFUL - created Nova Config\n"; else printf " --> ERROR - could not creat Nova Config - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (service nova-compute restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-compute service \n"; else printf " --> ERROR - could not restart nova-compute service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
rm -f /var/lib/nova/nova.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"

printf "
  ---------------------------------------
 | #### Finished Nova Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE
  
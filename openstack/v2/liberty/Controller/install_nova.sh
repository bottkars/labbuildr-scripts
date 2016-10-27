#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
CONTROLLERIP=$3

printf "
  ------------------------------------
 | #### Start Nova Installation ##### |
  ------------------------------------\n\n" | tee -a $LOGFILE
 
 printf " ### Install Packages\n" | tee -a $LOGFILE
 if (apt-get install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Nova Packages\n"; else printf " --> ERROR - could not install Nova Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
 
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
enabled_apis=osapi_compute,metadata
my_ip = $CONTROLLERIP
network_api_class = nova.network.neutronv2.api.API
security_group_api = neutron
linuxnet_interface_driver = nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
verbose = True
rpc_backend = rabbit
auth_strategy = keystone
metadata_host = \$my_ip

[database]
connection = mysql+pymysql://nova:Password123!@$CONTROLLERNAME/nova
[oslo_messaging_rabbit]
rabbit_host = $CONTROLLERNAME
rabbit_userid = nova_ctrl
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
vncserver_listen = \$my_ip
vncserver_proxyclient_address = \$my_ip

[glance]
host = $CONTROLLERNAME

[oslo_concurrency]
lock_path = /var/lib/nova/tmp
" > /etc/nova/nova.conf); then printf " --> SUCCESSFUL - created Nova Config\n"; else printf " --> ERROR - could not creat Nova Config - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (su -s /bin/sh -c "nova-manage db sync" nova) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated Nova Database\n"; else printf " --> ERROR - could not populated Nova Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (service nova-api restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-api service \n"; else printf " --> ERROR - could not restart nova-api service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (service nova-consoleauth restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-consoleauth service \n"; else printf " --> ERROR - could not restart nova-consoleauth service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (service nova-scheduler restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-scheduler service \n"; else printf " --> ERROR - could not restart nova-scheduler service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (service nova-conductor restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-conductor service \n"; else printf " --> ERROR - could not restart nova-conductor service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (service nova-novncproxy restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-novncproxy service \n"; else printf " --> ERROR - could not restart nova-novncproxy service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

rm -f /var/lib/nova/nova.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"

printf "
  ---------------------------------------
 | #### Finished Nova Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE

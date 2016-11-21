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
log-dir=/var/log/nova
state_path=/var/lib/nova
force_dhcp_release=True
verbose=True
ec2_private_dns_show_ip=True
enabled_apis=osapi_compute,metadata

transport_url = rabbit://nova_compute:Password123!@$CONTROLLERNAME
auth_strategy = keystone
my_ip = $LOCALIP
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver

[keystone_authtoken]
auth_uri = http://$CONTROLLERNAME:5000
auth_url = http://$CONTROLLERNAME:35357
memcached_servers = $CONTROLLERNAME:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = Password123!

[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = \$my_ip
novncproxy_base_url = http://$CONTROLLERNAME:6080/vnc_auto.html

[glance]
api_servers = http://$CONTROLLERNAME:9292

[libvirt]
use_virtio_for_bridges=True

[wsgi]
api_paste_config=/etc/nova/api-paste.ini


[oslo_concurrency]
lock_path = /var/lib/nova/tmp
" > /etc/nova/nova.conf); then printf " --> SUCCESSFUL - created Nova Config\n"; else printf " --> ERROR - could not creat Nova Config - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (service nova-compute restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-compute service \n"; else printf " --> ERROR - could not restart nova-compute service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
rm -f /var/lib/nova/nova.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"

printf "
  ---------------------------------------
 | #### Finished Nova Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE
  
#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
CONTROLLERIP=$3

printf "
  ------------------------------------
 | #### Started Nova Installation ##### |
  ------------------------------------\n\n" | tee -a $LOGFILE
 
 printf " ### Install Packages\n" | tee -a $LOGFILE
 if (apt-get install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Nova Packages\n"; else printf " --> ERROR - could not install Nova Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
 
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

transport_url = rabbit://nova_ctrl:Password123!@$CONTROLLERNAME
auth_strategy = keystone
my_ip = $CONTROLLERIP
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver

[api_database]
connection = mysql+pymysql://nova:Password123!@$CONTROLLERNAME/nova_api

[database]
connection = mysql+pymysql://nova:Password123!@$CONTROLLERNAME/nova

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

[glance]
api_servers = http://$CONTROLLERNAME:9292

[vnc]
vncserver_listen = \$my_ip
vncserver_proxyclient_address = \$my_ip

[oslo_concurrency]
lock_path=/var/lock/nova

[libvirt]
use_virtio_for_bridges=True

[wsgi]
api_paste_config=/etc/nova/api-paste.ini

" > /etc/nova/nova.conf); then printf " --> SUCCESSFUL - created Nova Config\n"; else printf " --> ERROR - could not creat Nova Config - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (su -s /bin/sh -c "nova-manage api_db sync" nova) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated nova_api Database\n"; else printf " --> ERROR - could not populated nova_api Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (su -s /bin/sh -c "nova-manage db sync" nova) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated nova Database\n"; else printf " --> ERROR - could not populated nova Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
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

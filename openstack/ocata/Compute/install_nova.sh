#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
LOCALIP=$3
INSTALLPATH=$4

printf "
  ------------------------------------
 | #### Start Nova Installation ##### |
  ------------------------------------\n\n" | tee -a $LOGFILE
 
 printf " ### Install Packages\n" | tee -a $LOGFILE
 if (apt-get install ipxe-qemu=1.0.0+git-20150424.a25a16d-1ubuntu1 qemu-block-extra:amd64=1:2.5+dfsg-5ubuntu10.9 qemu-kvm=1:2.5+dfsg-5ubuntu10.9 qemu-system-common=1:2.5+dfsg-5ubuntu10.9 qemu-system-x86=1:2.5+dfsg-5ubuntu10.9 qemu-utils=1:2.5+dfsg-5ubuntu10.9 libvirt-bin=1.3.1-1ubuntu10.8 libvirt0:amd64=1.3.1-1ubuntu10.8 python-libvirt=1.3.1-1ubuntu1 nova-compute sshpass -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Nova Packages\n"; else printf " --> ERROR - could not install Nova Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
 
printf " ### Configure Nova \n"

	if (cp ${INSTALLPATH}/configs/nova.conf /etc/nova/nova.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied nova.conf file \n"; else printf " --> ERROR - Could not copy nova.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	
	sed -i '/my_ip = x.x.x.x/c\my_ip = '$LOCALIP /etc/nova/nova.conf
	sed -i '/memcached_servers = */c\memcached_servers = '$CONTROLLERNAME':11211' /etc/nova/nova.conf
	sed -i '/transport_url = */c\transport_url = rabbit://nova_compute:Password123!@'$CONTROLLERNAME  /etc/nova/nova.conf
	sed -i '/auth_uri = nova_uri/c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/nova/nova.conf
	sed -i '/auth_url = nova_url/c\auth_url = http://'$CONTROLLERNAME':35357' /etc/nova/nova.conf
	sed -i '/api_servers = */c\api_servers = http://'$CONTROLLERNAME':9292' /etc/nova/nova.conf
	sed -i '/novncproxy_base_url = /c\novncproxy_base_url =http://'$CONTROLLERNAME':6080/vnc_auto.html' /etc/nova/nova.conf

	
if (service nova-compute restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted nova-compute service \n"; else printf " --> ERROR - could not restart nova-compute service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
rm -f /var/lib/nova/nova.sqlite; printf " --> SUCCESSFUL - Removed Dummy Database \n"

printf " ### Discover Compute Nodes on Controller \n"
if (ssh-keyscan -H $CONTROLLERNAME >> ~/.ssh/known_hosts)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Added $CONTROLLERNAME SSH Key to ~/.ssh/known_hosts \n"; else printf " --> ERROR - could not add $CONTROLLERNAME SSH Key to ~/.ssh/known_hosts \n" | tee -a $LOGFILE; fi
if (sshpass -p 'Password123!' ssh root@$CONTROLLERNAME /bin/bash /root/discover_hosts.sh)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Discovered Compute Nodes on $CONTROLLERNAME \n";  else printf " --> ERROR - could not discover Compute Nodes on $CONTROLLERNAME \n" | tee -a $LOGFILE; fi

printf "
  ---------------------------------------
 | #### Finished Nova Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE
  
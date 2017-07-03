#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
INSTALLPATH=$3
SWIFTLAYOUT=$4

printf "
  ------------------------------------------
 | #### Started Swift Installation ##### |
  ------------------------------------------\n\n" | tee -a $LOGFILE
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install swift swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached jq -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Swift Packages\n"; else printf " --> ERROR - could not install Swift Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Configure Swift \n" | tee -a $LOGFILE
	if (mkdir /etc/swift) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - created /etc/swift directory \n"; else printf " --> ERROR - could not create /etc/swift directory - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (cp ${INSTALLPATH}/configs/proxy-server.conf /etc/swift/proxy-server.conf) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL - Copied proxy-server.conf file \n"; else printf " --> ERROR - Could not copy proxy-server.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${INSTALLPATH}/configs/swift.conf /etc/swift/swift.conf) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL - Copied swift.conf file \n"; else printf " --> ERROR - Could not copy swift.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 

	sed -i '/auth_uri = */c\auth_uri = http://'$CONTROLLERNAME':5000' /etc/swift/proxy-server.conf
	sed -i '/auth_url = */c\auth_url = http://'$CONTROLLERNAME':35357' /etc/swift/proxy-server.conf
	sed -i '/memcached_servers = */c\memcached_servers = '$CONTROLLERNAME':11211' /etc/swift/proxy-server.conf
	sed -i '/memcache_servers = */c\memcache_servers = '$CONTROLLERNAME':11211' /etc/swift/proxy-server.conf

printf " ### Configure Swift Rings \n" | tee -a $LOGFILE
	
	#Jump to Swift Dir
	cd /etc/swift
	
	if (swift-ring-builder account.builder create 10 3 1) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created account.builder ring \n"; else printf " --> ERROR - could not create account.builder ring - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi	
	if (swift-ring-builder container.builder create 10 3 1) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created container.builder ring \n"; else printf " --> ERROR - could not create container.builder ring - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi	
	if (swift-ring-builder object.builder create 10 3 1) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created object.builder ring \n"; else printf " --> ERROR - could not create object.builder ring - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi	
	
	### Create Member from JSON File
	#Anzahl der nodes mit NODE_TYPE "compute"
	NODE_COUNT=$(echo $SWIFTLAYOUT | jq '. | map(select(.NODE_TYPE == "compute")) | length')
	
	#Loop runs through all compute nodes in json
	NODE=0
	while [ "$NODE" -lt "$NODE_COUNT" ]; do

		#Current Node count disks
		NODE_DEVICE_COUNT=$(echo $SWIFTLAYOUT | jq '.['$NODE'].swiftdisks | length')
		NODE_IP=$(echo $SWIFTLAYOUT | jq '.['$NODE'].NODE_IP')

		#Loop runs through all disks in current compute node
		DEVICE=0
		while [ "$DEVICE" -lt "$NODE_DEVICE_COUNT" ]; do
				DISK=$(echo $SWIFTLAYOUT | jq '.['$NODE'].swiftdisks['$DEVICE']')
				if(swift-ring-builder account.builder add --region 1 --zone 1 --ip ${NODE_IP:1:-1} --port 6202 --device ${DISK:6:-1} --weight 100) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Added ${NODE_IP:1:-1} with ${DISK:6:-1} to Account-Builder-Ring \n"; else printf " --> ERROR - could not add ${NODE_IP:1:-1} with ${DISK:6:-1} to Account-Builder-Ring  - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
				if(swift-ring-builder container.builder add --region 1 --zone 1 --ip ${NODE_IP:1:-1} --port 6201 --device ${DISK:6:-1} --weight 100) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Added ${NODE_IP:1:-1} with ${DISK:6:-1} to Container-Builder-Ring \n"; else printf " --> ERROR - could not add ${NODE_IP:1:-1} with ${DISK:6:-1} to Container-Builder-Ring  - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
				if(swift-ring-builder object.builder add --region 1 --zone 1 --ip ${NODE_IP:1:-1} --port 6200 --device ${DISK:6:-1} --weight 100) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Added ${NODE_IP:1:-1} with ${DISK:6:-1} to Object-Builder-Ring \n"; else printf " --> ERROR - could not add ${NODE_IP:1:-1} with ${DISK:6:-1} to Object-Builder-Ring  - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
				let DEVICE=DEVICE+1
		done
		let NODE=NODE+1
	done

	if (swift-ring-builder account.builder rebalance) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Rebalanced account.builder ring \n"; else printf " --> ERROR - could not rebalance account.builder ring - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (swift-ring-builder container.builder rebalance) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Rebalanced container.builder ring \n"; else printf " --> ERROR - could not rebalance container.builder ring - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (swift-ring-builder object.builder rebalance) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Rebalanced object.builder ring \n"; else printf " --> ERROR - could not rebalance object.builder ring - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

	if (chown -R root:swift /etc/swift) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Set root:swift permission on /etc/swift \n"; else printf " --> ERROR - could not set root:swift permission on /etc/swift - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service memcached restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted  memcached service \n"; else printf " --> ERROR - could not restart  memcached service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service swift-proxy restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted swift-proxy service \n"; else printf " --> ERROR - could not restart swift-proxy service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf "
  ------------------------------------------
 | #### Finished Swift Installation ##### |
  ------------------------------------------\n\n" | tee -a $LOGFILE
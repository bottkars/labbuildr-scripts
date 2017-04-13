#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
LOCALIP=$3
INSTALLPATH=$4
SWIFTLAYOUT=$5

printf "
  ------------------------------------------
 | #### Start Swift Installation ##### |
  ------------------------------------------\n\n" | tee -a $LOGFILE
 
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install xfsprogs rsync swift swift-account swift-container swift-object sshpass jq -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Installed swift packages \n"; else printf " --> ERROR - Could not install swift packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (cp ${INSTALLPATH}/configs/swift.conf /etc/swift/swift.conf) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL - Copied swift.conf file \n"; else printf " --> ERROR - Could not copy swift.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${INSTALLPATH}/configs/account-server.conf /etc/swift/account-server.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied account-server.conf \n"; else printf " --> ERROR - Could not Copy account-server.conf - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (cp ${INSTALLPATH}/configs/container-server.conf /etc/swift/container-server.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied container-server.conf \n"; else printf " --> ERROR - Could not Copy container-server.conf - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (cp ${INSTALLPATH}/configs/object-server.conf /etc/swift/object-server.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied object-server.conf \n"; else printf " --> ERROR - Could not Copy object-server.conf - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (cp ${INSTALLPATH}/configs/rsyncd.conf /etc/rsyncd.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied rsyncd.conf \n"; else printf " --> ERROR - Could not Copy rsyncd.conf - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
	
	/etc/default/rsync
	sed -i '/bind_ip = */c\bind_ip = '$LOCALIP /etc/swift/account-server.conf
	sed -i '/bind_ip = */c\bind_ip = '$LOCALIP /etc/swift/container-server.conf
	sed -i '/bind_ip = */c\bind_ip = '$LOCALIP /etc/swift/object-server.conf
	sed -i '/address = */c\address = '$LOCALIP /etc/rsyncd.conf
	sed -i '/RSYNC_ENABLE=*/c\RSYNC_ENABLE=true' /etc/default/rsync


## Determine the amount of "compute" nodes in JSON File --> NODE_COUNT
## Go through each ComputeNode and check if the NODE_IP matches with local IP
## If match found, save all swiftdisks in this node into DISKS Array

NODE_COUNT=$(echo $SWIFTLAYOUT | jq '. | map(select(.NODE_TYPE == "compute")) | length')
NODE=0

while [ "$NODE" -lt "$NODE_COUNT" ]; do

		NODE_IP=$(echo $SWIFTLAYOUT | jq '.['$NODE'].NODE_IP')
		if [ "${NODE_IP:1:-1}" = "$LOCALIP" ]
		then
				NODE_DEVICE_COUNT=$(echo $SWIFTLAYOUT | jq '.['$NODE'].swiftdisks | length')
				DEVICE=0
				while [ "$DEVICE" -lt "$NODE_DEVICE_COUNT" ]; do
						DISK=$(echo $SWIFTLAYOUT | jq '.['$NODE'].swiftdisks['$DEVICE']')						
						if (mkfs.xfs ${DISK:1:-1}) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created Filesystem on ${DISK:1:-1} \n"; else printf " --> ERROR - Could not create Filesystem on ${DISK:1:-1} - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
						if (mkdir -p /srv/node/${DISK:6:-1}) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created ${DISK:6:-1} mount-point folder \n"; else printf " --> ERROR - Could not create ${DISK:6:-1} mount-point folder - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
						if (echo "${DISK:1:-1} /srv/node/${DISK:6:-1} xfs noatime,nodiratime,nobarrier,logbufs=8 0 2" >> /etc/fstab) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Added ${DISK:1:-1} mount to fstab \n"; else printf " --> ERROR - Could not add ${DISK:1:-1} mount to fstab - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
						if (mount /srv/node/${DISK:6:-1}) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Mounted ${DISK:6:-1} to /srv/node/${DISK:6:-1} \n"; else printf " --> ERROR - Could not mount ${DISK:6:-1} to /srv/node/${DISK:6:-1}  - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
						let DEVICE=DEVICE+1
				done
		fi
		let NODE=NODE+1
done

#printf '############# END  LOOP ################# \n\n'


	if (ssh-keyscan -H $CONTROLLERNAME >> ~/.ssh/known_hosts)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Added $CONTROLLERNAME SSH Key to ~/.ssh/known_hosts \n"; else printf " --> ERROR - could not add $CONTROLLERNAME SSH Key to ~/.ssh/known_hosts \n" | tee -a $LOGFILE; fi		
	if (sshpass -p 'Password123!' scp root@$CONTROLLERNAME:/etc/swift/*.gz /etc/swift/) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied Rings from $CONTROLLERNAME to /etc/swift/ \n"; else printf " --> ERROR - Could not copy Rings from $CONTROLLERNAME to /etc/swift/ - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

	if (service rsync start) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Restarted service rsync \n"; else printf " --> ERROR - Could not restart service rsync - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (chown -R swift:swift /srv/node) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Changed ownership on /srv/node to swift:swift \n"; else printf " --> ERROR - Could not change ownership on /srv/node to swift:swift - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (mkdir -p /var/cache/swift) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Created /var/cache/swift directory \n"; else printf " --> ERROR - Could not create /var/cache/swift directory - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (chown -R root:swift /var/cache/swift) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Changed ownership on /var/cache/swift to swift:swift \n"; else printf " --> ERROR - Could not change ownership on /var/cache/swift to swift:swift - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (chmod -R 775 /var/cache/swift) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Changed permissions on /var/cache/swift to 755 \n"; else printf " --> ERROR - Could not change permissions on /var/cache/swift to 755 - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (chown -R root:swift /etc/swift) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Changed ownership on /etc/swift to swift:swift \n"; else printf " --> ERROR - Could not change ownership on /etc/swift to swift:swift - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
	if (swift-init all start) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Started Object Storage Services \n"; else printf " --> ERROR - Could not start Object Storage Services - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
printf "
  ------------------------------------------
 | #### Finished Swift Installation ##### |
  ------------------------------------------\n\n" | tee -a $LOGFILE








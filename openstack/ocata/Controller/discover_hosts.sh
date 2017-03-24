#!/bin/bash

LOGFILE="/tmp/os_install.log"

printf " ### Discover Compute Nodes on Controller \n"
if (su -s /bin/sh -c "nova-manage cell_v2 discover_hosts" nova)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Discovered Compute Nodes on $CONTROLLERNAME \n";  else printf " --> ERROR - could not discover Compute Nodes on $CONTROLLERNAME \n" | tee -a $LOGFILE; fi

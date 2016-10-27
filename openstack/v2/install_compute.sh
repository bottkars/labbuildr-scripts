#!/bin/bash

LOGFILE="/tmp/os_install.log"
INSTALLPATH=$(dirname "${BASH_SOURCE[0]}")
OSVERSION="mitaka"
CONFIGPATH="$INSTALLPATH/$OSVERSION/Compute"
LOCALNAME=$(hostname)
LOCALIP=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')

CONTROLLERNAME="ubuntu3"
CONTROLLERIP="192.168.2.203"

### Starting actual Installation Workflow
printf "\n
########################################################
####### Start Openstack Compute Installation ########
########################################################\n\n" | tee -a $LOGFILE

printf " # Systemdetails
 ## System
 ### Local IP:\t\t\t\t $LOCALIP
 ### Local Hostname: \t\t\t $LOCALNAME\n
 ## Controller
 ### ControllerName:\t\t $CONTROLLERNAME
 ### ControllerIP:\t\t $CONTROLLERIP
 ## Environment
 ## Openstack
 ### Version:\t\t\t $OSVERSION
" | tee -a $LOGFILE

printf " ## Prepare Environment\n"  | tee -a $LOGFILE

printf " ### Check if Node supports hardware acceleration\n"
		if (( $(egrep -c '(vmx|svm)' /proc/cpuinfo) == 0 )); then
				printf " #### WARNING: Node does not support hardware acceleration #### \n"
				printf " #### If you are using VMware Workstation - enable \"Virtualize Intel VT-x/EPT or AMD-V/RVI\" \n"
			else
				printf " --> SUCCESSFUL - This Node does support hardware acceleration. \n"
		fi

if (find $INSTALLPATH -name *.sh -exec chmod +x {} \;) >> $LOGFILE 2>&1; then 
	printf " --> SUCCESSFUL made scripts executable\n"; else printf " --> ERROR - could not make scripts executable - Logfile: $LOGFILE \n"; fi

if (apt-get install software-properties-common -y && add-apt-repository cloud-archive:$OSVERSION -y ) >> $LOGFILE 2>&1; then
	printf " --> SUCCESSFUL added $OSVERSION Repository \n"; else printf " --> ERROR - could not add $OSVERSION Repository - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (apt-get update) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL updated Package list \n"; else printf " --> ERROR - could not update Package list - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf "
  -----------------------------------
 | #### Done with Base install ##### |
  -----------------------------------\n\n" | tee -a $LOGFILE


${CONFIGPATH}/install_nova.sh $LOGFILE $CONTROLLERNAME $LOCALIP
${CONFIGPATH}/install_neutron.sh $LOGFILE $CONTROLLERNAME $LOCALIP $CONFIGPATH

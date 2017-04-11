#!/bin/bash

LOGFILE="/tmp/os_install.log"
INSTALLPATH=$(dirname "${BASH_SOURCE[0]}")
LOCALNAME=$(hostname)
LOCALIP=$(ifconfig ens160 | awk '/inet addr/{print substr($2,6)}')
SWIFTLAYOUT='[{"NODE_TYPE":"compute","swiftdisks":["/dev/sdc","/dev/sdd"],"NODE_NAME":"ubuntu4","NODE_IP":"192.168.2.204"},{"NODE_TYPE":"compute","NODE_NAME":"ubuntu5","NODE_IP":"192.168.2.205","swiftdisks":["/dev/sdc","/dev/sdd"]},{"NODE_TYPE":"controller","NODE_NAME":"ubuntu6","NODE_IP":"192.168.2.206"}]'

while [ $# -gt 1 ]
do
key="$1"
case $key in
    -cip|--controllerip)
		CONTROLLERIP="$2"
		shift # past argument
    ;;
	-cname|--controller_name)
		CONTROLLERNAME="$2"
    shift # past argument
    ;;
	-sl | --swiftdisks)
		SWIFTLAYOUT="$2"
		shift
	;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

# Check if controllerip and ist set
	if [ -z $CONTROLLERIP ]; then 
		printf "Please set Controller IP
[-cip | --controllerip] X.X.X.X \n"
		exit
	fi
# Check if controller_name and ist set
	if [ -z $CONTROLLERNAME ]; then 
		printf "Please set Controller Name
[-cname | --controller_name] X.X.X.X \n"
		exit
	fi	
	

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
 ### Version:\t\t\t Ocata
" | tee -a $LOGFILE

printf " ### Check if Node supports hardware acceleration\n"
		if (( $(egrep -c '(vmx|svm)' /proc/cpuinfo) == 0 )); then
				printf " #### WARNING: Node does not support hardware acceleration #### \n"
				printf " #### If you are using VMware Workstation - enable \"Virtualize Intel VT-x/EPT or AMD-V/RVI\" \n\n"
			else
				printf " --> SUCCESSFUL - This Node does support hardware acceleration. \n"
		fi

printf " ## Prepare Environment\n"  | tee -a $LOGFILE
	if (find $INSTALLPATH -name "*.sh" -exec chmod +x {} \;) >> $LOGFILE 2>&1; then 
		printf " --> SUCCESSFUL made scripts executable\n"; else printf " --> ERROR - could not make scripts executable - Logfile: $LOGFILE \n"; fi

	if (apt-get install software-properties-common -y && add-apt-repository cloud-archive:ocata -y ) >> $LOGFILE 2>&1; then
		printf " --> SUCCESSFUL added Ocata Repository \n"; else printf " --> ERROR - could not add Ocata Repository - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

	if (apt-get update) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL updated Package list \n"; else printf " --> ERROR - could not update Package list - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf "
  -----------------------------------
 | #### Done with Base install ##### |
  -----------------------------------\n\n" | tee -a $LOGFILE

${INSTALLPATH}/install_nova.sh $LOGFILE $CONTROLLERNAME $LOCALIP $INSTALLPATH
${INSTALLPATH}/install_neutron.sh $LOGFILE $CONTROLLERNAME $LOCALIP $INSTALLPATH
${INSTALLPATH}/install_swift.sh $LOGFILE $CONTROLLERNAME $LOCALIP $INSTALLPATH $SWIFTLAYOUT

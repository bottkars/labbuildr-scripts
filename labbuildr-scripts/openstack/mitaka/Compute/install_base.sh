#!/bin/bash
#### Define Colors
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$(hostname)
LOCALIP=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')
DOCKER="false"

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
   -d | --docker)
        DOCKER="$2"
        shift # past argument
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
	
#Switch to script dir
cd "$( dirname "${BASH_SOURCE[0]}" )"


### Starting actual Installation Workflow
printf $yellow "
 ####################################################
 #### Start Openstack Compute Node Installation #####
 ####################################################"

	printf "\n #### Systemdetails\n"
		printf " ### Controller IP\t\t\t:$CONTROLLERIP \n"
		printf " ### Controller Name\t\t\t:$CONTROLLERNAME \n"
		printf " ### Local IP used\t\t\t:$LOCALIP \n"
		printf " ### Local Hostname used\t\t:$LOCALHOSTNAME \n"
		if [ $DOCKER == "true" ]; then printf " ### This Host will become a Docker Host.\n"; else printf " ### This Host will become a libvirt Host.\n"; fi
	
printf " #### Prepare Installation\n"
	printf " ### Check if Node supports hardware acceleration\n"
		if (( $(egrep -c '(vmx|svm)' /proc/cpuinfo) == 0 )); then
				printf $red " #### WARNING: Node does not support hardware acceleration ####"
				printf $red " #### If you are using VMware Workstation - enable \"Virtualize Intel VT-x/EPT or AMD-V/RVI\" "
			else
				printf $green " --> Supported."
		fi

	printf " ### Create Log Files on /tmp/os_logs\t"
		if mkdir /tmp/os_logs && touch /tmp/os_logs/{general.log,nova.log,neutron.log,nova_docker.log} ; then
			printf $green " --> done"
	else	
		printf $red " ERROR --> Could not create Log Files"
	fi
	
	printf " ### Make Scripts executable\t"	
		if chmod +x * >> /tmp/os_logs/general.log 2>&1; then
			printf $green "--> done"
	else
		printf $red " ERROR --> Could not set permissions - see /tmp/os_logs/general.log"
	fi	


printf " #### Add Repositories\n"
	printf " ### Openstack Mitaka"
		if (apt-get install software-properties-common -y && add-apt-repository cloud-archive:mitaka -y) >> /tmp/os_logs/general.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " ERROR --> Could not add Mitaka Repo - see /tmp/os_logs/general.log"
		fi
	
	
printf " #### Install Basic Tools\n"

	printf " ### Update Package List"
		apt-get update >> /tmp/os_logs/general.log 2>&1
	printf $green " --> done"

	printf " ### Install Python-Pymysql and Python-Openstackclient"
		if apt-get install python-openstackclient python-pymysql -y >> /tmp/os_logs/general.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " ERROR --> Could not install Packages - see /tmp/os_logs/general.log"
		fi

./install_nova.sh $LOCALIP $CONTROLLERIP $CONTROLLERNAME
./install_neutron.sh $LOCALIP $CONTROLLERIP $CONTROLLERNAME
if [ $DOCKER == "true" ]; then ./install_docker.sh; fi










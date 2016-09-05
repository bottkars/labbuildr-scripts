#!/bin/bash
#### Define Colors
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$(hostname)
LOCALIP=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')

while [[ $# -gt 1 ]]
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
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

# Check if controllerip and ist set
#	if [ -z $CONTROLLERIP ]; then 
#		printf "Please set Controller IP
#[-cip | --controllerip] X.X.X.X \n"
#		exit
#	fi
# Check if controller_name and ist set
#	if [ -z $CONTROLLERNAME ]; then 
#		printf "Please set Controller Name
#[-cname | --controller_name] X.X.X.X \n"
#		exit
#	fi	
	
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

printf " #### Prepare Installation\n"
	printf " ### Check if Node supports hardware acceleration\n"
		if (( $(egrep -c '(vmx|svm)' /proc/cpuinfo) == 0 )); then
				printf $red " #### WARNING: Node does not support hardware acceleration ####"
				printf $red " #### If you are using VMware Workstation - enable \"Virtualize Intel VT-x/EPT or AMD-V/RVI\" "
			else
				printf $green " --> OK"
		fi

	printf " ### Create Log Files on $(pwd)/logs\t"
		if mkdir logs && touch ./logs/general.log ./logs/nova.log ./logs/neutron.log ; then
			printf $green " --> done"
	else	
		printf $red " --> Could not create Log Files"
	fi
	
	printf " ### Make Scripts executable\t"	
		if chmod +x install_nova.sh install_neutron.sh >> ./logs/general.log 2>&1; then
			printf $green "--> done"
	else
		printf $red " --> Could not set permissions - see $(pwd)/logs/general.log"
	fi	


printf " #### Add Repositories\n"
	printf " ### Openstack Liberty"
		if (apt-get install software-properties-common -y && add-apt-repository cloud-archive:liberty -y) >> ./logs/general.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not add Liberty Repo - see $(pwd)/logs/general.log"
		fi
	
	
printf " #### Install Basic Tools\n"

	printf " ### Update Package List"
		apt-get update >> ./logs/general.log 2>&1
	printf $green " --> done"

	printf " ### Install Python-Pymysql and Python-Openstackclient"
		if apt-get install python-openstackclient python-pymysql -y >> ./logs/general.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not install Packages - see $(pwd)/logs/general.log"
		fi

./install_nova.sh $LOCALIP $CONTROLLERIP $CONTROLLERNAME
./install_neutron.sh $LOCALIP $CONTROLLERIP $CONTROLLERNAME










#!/bin/bash
#### Define Colors
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

CONTROLLERNAME=$(hostname)
CONTROLLERIP=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')

#Parameter Handling
while [ $# -gt 1 ]
do
key="$1"
case $key in
    -spd|--scaleio_protection_domain)
        SIO_PD="$2"
        shift # past argument
    ;;
    -ssp|--scaleio_storage_pool)
        SIO_SP="$2"
        shift # past argument
    ;;
	-sgw|--scaleio_gateway)
        SIO_GW="$2"
        shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

#Switch to script dir
cd "$( dirname "${BASH_SOURCE[0]}" )"

#Check if SIO vars are specified by parameter
if [ -z $SIO_GW ]; then 
	printf "No ScaleIO Gateway has been specified. Assuming ScaleIO Gateway is local.\n"
	SIO_GW=$(hostname)
fi

if [ -z $SIO_PD ]; then 
	printf "No ScaleIO Protection Domain has been specified. Setting ScaleIO Protection Domain to \"default\" \n"
	SIO_PD="default"
fi

if [ -z $SIO_SP ]; then 
	printf "No ScaleIO Storage Pool has been specified. Setting ScaleIO Storage Pool to \"defaultSP\" \n"
	SIO_SP="defaultSP"
fi

### Starting actual Installation Workflow
printf $yellow "
####################################################
##### Start Openstack Controller Installation ######
####################################################"

	printf "\n #### Systemdetails\n"
		printf " ### Controller IP\t\t\t:$CONTROLLERIP \n"
		printf " ### Controller Name\t\t\t:$CONTROLLERNAME \n"
		printf " ### ScaleIO Gateway\t\t\t:$SIO_GW \n"
		printf " ### ScaleIO Protection Domain\t\t:$SIO_PD \n"
		printf " ### ScaleIO Storage Pool\t\t:$SIO_SP \n"
		
		
printf " #### Prepare Installation\n"

	printf " ### Create Log Files on $(pwd)/logs\t"
		if 	mkdir logs && touch ./logs/general.log ./logs/mysql.log ./logs/rabbitmq.log ./logs/keystone.log ./logs/glance.log ./logs/nova.log ./logs/neutron.log ./logs/cinder.log ./logs/horizon.log; then
			printf $green " --> done"
		else	
			printf $red " --> Could not create Log Files"
		fi

	printf " ### Make Scripts executable\t"
		if (chmod +x install_mysql.sh install_rabbitmq.sh install_keystone.sh install_glance.sh install_nova.sh install_neutron.sh install_cinder.sh install_horizon.sh) >> ./logs/general.log 2>&1; then
			printf $green "--> done"
		else
			printf $red " --> Could not set permissions - see $(pwd)/logs/general.log"
		fi
	
printf " #### Add Repositories\n"
	printf " ### MariaDB"
		if (apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror2.hs-esslingen.de/mariadb/repo/10.1/ubuntu trusty main') >> ./logs/general.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not add MariaDB Repo - see $(pwd)/logs/general.log"
		fi

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
	
./install_mysql.sh $CONTROLLERNAME $CONTROLLERIP 
./install_rabbitmq.sh
./install_keystone.sh $CONTROLLERNAME
./install_glance.sh $CONTROLLERNAME $CONTROLLERIP
./install_nova.sh $CONTROLLERNAME $CONTROLLERIP
./install_neutron.sh $CONTROLLERNAME $CONTROLLERIP
./install_cinder.sh $CONTROLLERNAME $CONTROLLERIP $SIO_GW $SIO_PD $SIO_SP
./install_horizon.sh $CONTROLLERNAME $CONTROLLERIP










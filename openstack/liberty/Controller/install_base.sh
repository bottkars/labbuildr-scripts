#!/bin/bash
#### Define Colors
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

CONTROLLERNAME=$(hostname)
CONTROLLERIP=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')
CONFIG="true"

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
    -d | --domain)
        LABDOMAIN="$2"
        shift # past argument
    ;;
    -c | --config)
        CONFIG="$2"
        shift # past argument
    ;;
    *)
	printf "usage: install_base.sh
		\t [ --scaleio_protection_domain | -spd ] <ScaleIO Protection Domain Name>
		\t [ scaleio_storage_pool | -ssp ] <ScaleIO Storage Pool Name>
		\t [ --scaleio_gateway | -sgw ] < ScaleIO Gateway IP | ScaleIO Gateway Hostname>
		\t [ --domain | -d ] <Labbuildr Domain Name>
		\t [ --config | -c ] <true | false>
	"
	;;
esac
shift # past argument or value
done

#Switch to script dir
cd "$( dirname "${BASH_SOURCE[0]}" )"

#Check if SIO vars are specified by parameter
printf "\n\n\n"
if [ -z $SIO_GW ]; then 
	printf " !!! No ScaleIO Gateway has been specified. Assuming ScaleIO Gateway is local.\n "
	SIO_GW=$(hostname)
fi

if [ -z $SIO_PD ]; then 
	printf " !!! No ScaleIO Protection Domain has been specified. Setting ScaleIO Protection Domain to \"PD_labbuildr\" \n "
	SIO_PD="PD_labbuildr"
fi

if [ -z $SIO_SP ]; then 
	printf " !!! No ScaleIO Storage Pool has been specified. Setting ScaleIO Storage Pool to \"SP_labbuildr\" \n "
	SIO_SP="SP_labbuildr"
fi
if [ -z $LABDOMAIN ]; then 
	printf " !!! No Labdomain has been specified. Setting Labdomain do  \"labbuildr\" \n "
	LABDOMAIN="labbuildr"
fi

if [ $CONFIG == "true" ] || [ $CONFIG == "false" ]; then
	printf "\n"
else
	printf " !!! Config parameter has not been recognized. Setting it to true\n"
	CONFIG="true"
	printf " !!! Openstack will be installed with base config.\n"
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
		if [ $CONFIG == "true" ]; then printf " ### Openstack will be installed with base config.\n"; else printf " ### Openstack will be installed without base config.\n"; fi
		
printf " #### Prepare Installation\n"

	printf " ### Create Log Files on /tmp/os_logs\t "
		if 	mkdir -p /tmp/os_logs && touch /tmp/os_logs/general.log /tmp/os_logs/mysql.log /tmp/os_logs/rabbitmq.log /tmp/os_logs/keystone.log /tmp/os_logs/glance.log /tmp/os_logs/nova.log /tmp/os_logs/neutron.log /tmp/os_logs/cinder.log /tmp/os_logs/horizon.log /tmp/os_logs/heat.log /tmp/os_logs/conf_env.log; then
			printf $green " --> done"
		else	
			printf $red " --> Could not create Log Files "
		fi

	printf " ### Make Scripts executable\t "
		if (chmod +x install_mysql.sh install_rabbitmq.sh install_keystone.sh install_glance.sh install_nova.sh install_neutron.sh install_cinder.sh install_horizon.sh configure_environment.sh install_heat.sh) >> /tmp/os_logs/general.log 2>&1; then
			printf $green "--> done"
		else
			printf $red " --> Could not set permissions - see /tmp/os_logs/general.log"
		fi
	
printf " #### Add Repositories\n"
	printf " ### MariaDB "
		if (apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror2.hs-esslingen.de/mariadb/repo/10.1/ubuntu trusty main') >> /tmp/os_logs/general.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not add MariaDB Repo - see /tmp/os_logs/general.log"
		fi

	printf " ### Openstack Liberty "
		if (apt-get install software-properties-common -y && add-apt-repository cloud-archive:liberty -y) >> /tmp/os_logs/general.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not add Liberty Repo - see /tmp/os_logs/general.log"
		fi

printf " #### Install Basic Tools\n"

	printf " ### Update Package List "
		apt-get update >> /tmp/os_logs/general.log 2>&1
	printf $green " --> done"
	
	printf " ### Install Python-Pymysql and Python-Openstackclient "
		if apt-get install python-openstackclient python-pymysql -y >> /tmp/os_logs/general.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not install Packages - see /tmp/os_logs/general.log"
		fi
	
./install_mysql.sh $CONTROLLERNAME $CONTROLLERIP 
./install_rabbitmq.sh
./install_keystone.sh $CONTROLLERNAME
./install_glance.sh $CONTROLLERNAME $CONTROLLERIP
./install_nova.sh $CONTROLLERNAME $CONTROLLERIP
./install_neutron.sh $CONTROLLERNAME $CONTROLLERIP
./install_cinder.sh $CONTROLLERNAME $CONTROLLERIP $SIO_GW $SIO_PD $SIO_SP
./install_horizon.sh $CONTROLLERNAME $CONTROLLERIP
./install_heat.sh $CONTROLLERNAME
if [ $CONFIG == "true" ]; then ./configure_environment.sh $LABDOMAIN; fi


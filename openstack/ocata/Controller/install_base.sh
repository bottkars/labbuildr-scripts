#!/bin/bash

LOGFILE="/tmp/os_install.log"
INSTALLPATH=$(dirname "${BASH_SOURCE[0]}")
CONTROLLERNAME=$(hostname)
CONTROLLERIP=$(ifconfig ens160 | awk '/inet addr/{print substr($2,6)}')


BUILDDOMAIN="labbuildr"		#Default
DOMAINSUFFIX="local"			#Default
SIO_PD="PD_labbuildr"			#Default
SIO_SP="SP_labbuildr"			#Default
SIO_GW=$(hostname)			#Default
UNITYIP="192.168.2.171"	#Default
UNITYPOOL="vPool"				#Default
CINDERBACKENDS="scaleio"	#Default
BASECONFIG="true"				#Default

#SWIFTLAYOUT='[{"NODE_TYPE":"compute","swiftdisks":["/dev/sdc","/dev/sdd"],"NODE_NAME":"ubuntu4","NODE_IP":"192.168.2.204"},{"NODE_TYPE":"compute","NODE_NAME":"ubuntu5","NODE_IP":"192.168.2.205","swiftdisks":["/dev/sdc","/dev/sdd"]},{"NODE_TYPE":"controller","NODE_NAME":"ubuntu6","NODE_IP":"192.168.2.206"}]'
SWIFTLAYOUT=

#Parameter Handling
while [ $# -gt 1 ]
do
key="$1"
case $key in
	 -d | --domain)
        BUILDDOMAIN="$2"
        shift # past argument
    ;;	
	-s | --suffix)
        DOMAINSUFFIX="$2"
        shift # past argument
    ;;	
	-cb | --cinderbackends)
        CINDERBACKENDS="$2"
        shift # past argument
	;;
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
	-uip | --unityip)
        UNITYIP="$2"
        shift # past argument
	;;
	-up | --unitypool)
        UNITYPOOL="$2"
        shift # past argument
	;;
	 -c | --config)
        BASECONFIG="$2"
        shift # past argument
	;;
		 -sl | --swiftdisks)
        SWIFTLAYOUT="$2"
        shift # past argument
	;;
    *)
	printf "usage: install_base.sh
		\t [ --domain | -d ] <Labbuildr Domain Name>
		\t [ --suffix | -s <domain suffix>]
		\t [ --cinderbackends | -cb ] <scaleio | unity>
		\t [ --scaleio_protection_domain | -spd ] <ScaleIO Protection Domain Name>
		\t [ --scaleio_storage_pool | -ssp ] <ScaleIO Storage Pool Name>
		\t [ --scaleio_gateway | -sgw ] < ScaleIO Gateway IP | ScaleIO Gateway Hostname>
		\t [ --unityip | -uip ] <Unity IP | Unity Hostname>
		\t [ --unitypool | -up ] < Unity Storage Pool>
		\t [ --config | -c ] <true | false>
	"
	;;
esac
shift # past argument or value
done


### Starting actual Installation Workflow
printf "\n
########################################################
####### Start Openstack Controller Installation ########
########################################################\n\n" | tee -a $LOGFILE

printf " # Systemdetails
 ## System
 ### ControllerName:\t\t $CONTROLLERNAME
 ### ControllerIP:\t\t $CONTROLLERIP
 ### Domain:\t\t\t $BUILDDOMAIN
 ### DomainSuffix:\t\t $DOMAINSUFFIX\n
 ## ScaleIO
 ### ScaleIO Gateway:\t\t $SIO_GW
 ### ScaleIO Protection Domain:\t $SIO_PD
 ### ScaleIO Storage Pool:\t $SIO_SP \n
 ## Openstack
 ### Cinder Backends: \t\t $CINDERBACKENDS
 ### BaseConfig:\t\t $BASECONFIG \n\n" | tee -a $LOGFILE

 
printf " ## Prepare Environment\n"  | tee -a $LOGFILE
if (find $INSTALLPATH -name "*.sh" -exec chmod +x {} \;) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL made scripts executable\n"; else printf " --> ERROR - could not make scripts executable - Logfile: $LOGFILE \n"; fi

if (apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 && add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror2.hs-esslingen.de/mariadb/repo/10.1/ubuntu xenial main') >> $LOGFILE 2>&1; then
	printf " --> SUCCESSFUL added MariaDB Repository\n"; else printf " --> ERROR - could not add MariaDB Repository - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (apt-get install software-properties-common -y && add-apt-repository cloud-archive:ocata -y ) >> $LOGFILE 2>&1; then
	printf " --> SUCCESSFUL added Ocata Repository \n"; else printf " --> ERROR - could not add Ocata Repository - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (apt-get update) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL updated Package list \n"; else printf " --> ERROR - could not update Package list - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
if (apt-get install python-openstackclient python-pymysql -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL installed Python Clients \n"; else printf " --> ERROR - could not add Python clients - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ## Install Memcache\n"  | tee -a $LOGFILE
	if (apt-get install memcached -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL installed memcache \n"; else printf " --> ERROR - could not install memcache - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	sed -i '/-l 127.*/c\-l '$CONTROLLERIP /etc/memcached.conf | tee -a $LOGFILE 2>&1
	if (service memcached restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted memcached service \n"; else printf " --> ERROR - could not restart memcached service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf "
  -----------------------------------
 | #### Done with Base install ##### |
  -----------------------------------\n\n" | tee -a $LOGFILE


${INSTALLPATH}/install_mysql.sh $LOGFILE $CONTROLLERIP $INSTALLPATH
${INSTALLPATH}/install_rabbitmq.sh $LOGFILE
${INSTALLPATH}/install_keystone.sh $LOGFILE $CONTROLLERNAME $INSTALLPATH
${INSTALLPATH}/install_glance.sh $LOGFILE $CONTROLLERNAME $INSTALLPATH
${INSTALLPATH}/install_nova.sh $LOGFILE $CONTROLLERNAME $CONTROLLERIP $INSTALLPATH
${INSTALLPATH}/install_neutron.sh $LOGFILE $CONTROLLERNAME $CONTROLLERIP $BUILDDOMAIN $DOMAINSUFFIX $INSTALLPATH
${INSTALLPATH}/install_horizon.sh $LOGFILE $CONTROLLERNAME $INSTALLPATH
${INSTALLPATH}/install_heat.sh $LOGFILE $CONTROLLERNAME $INSTALLPATH
${INSTALLPATH}/install_cinder.sh $LOGFILE $CONTROLLERNAME $CONTROLLERIP $SIO_GW $SIO_PD $SIO_SP $INSTALLPATH $UNITYIP $UNITYPOOL $CINDERBACKENDS
if [ -n "$SWIFTLAYOUT" ]; then ${INSTALLPATH}/install_swift.sh $LOGFILE $CONTROLLERNAME $INSTALLPATH $SWIFTLAYOUT ; fi
if [ $BASECONFIG = "true" ]; then ${INSTALLPATH}/conf_env.sh $LOGFILE $CONTROLLERNAME $BUILDDOMAIN $CINDERBACKENDS; fi 

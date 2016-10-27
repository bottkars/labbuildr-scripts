#!/bin/bash

LOGFILE="/tmp/os_install.log"
INSTALLPATH=$(dirname "${BASH_SOURCE[0]}")
OSVERSION="mitaka"
CONFIGPATH="$INSTALLPATH/$OSVERSION/Controller/"
CONTROLLERNAME=$(hostname)
CONTROLLERIP=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')
DOMAINSUFFIX=$(grep -oPm1 "(?<=<Custom_DomainSuffix>)[^<]+" $INSTALLPATH/defaults.xml )
BUILDDOMAIN=$(grep -oPm1 "(?<=<BuildDomain>)[^<]+" $INSTALLPATH/defaults.xml )
MYSUBNET=$(grep -oPm1 "(?<=<MySubnet>)[^<]+" $INSTALLPATH/defaults.xml )
DEFGW=$(grep -oPm1 "(?<=<DefaultGateway>)[^<]+" $INSTALLPATH/defaults.xml )
DNS1=$(grep -oPm1 "(?<=<DNS1>)[^<]+" $INSTALLPATH/defaults.xml )
DNS2=$(grep -oPm1 "(?<=<DNS2>)[^<]+" $INSTALLPATH/defaults.xml )
SIO_GW=$(hostname)
SIO_PD="PD_labbuildr"
SIO_SP="SP_labbuildr"
BASECONFIG="true"


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
 ## Environment
 ### Subnet:\t\t\t $MYSUBNET
 ### Default Gateway:\t\t $DEFGW
 ### DNS Server:\t\t $DNS1 $DNS2 \n
 ## ScaleIO
 ### ScaleIO Gateway:\t\t $SIO_GW
 ### ScaleIO Protection Domain:\t $SIO_PD
 ### ScaleIO Storage Pool:\t $SIO_SP \n
 ## Openstack
 ### Version:\t\t\t $OSVERSION
 ### BaseConfig:\t\t $BASECONFIG \n\n" | tee -a $LOGFILE
 

printf " ## Prepare Environment\n"  | tee -a $LOGFILE
if (find $INSTALLPATH -name *.sh -exec chmod +x {} \;) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL made scripts executable\n"; else printf " --> ERROR - could not make scripts executable - Logfile: $LOGFILE \n"; fi

if (apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db && add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror2.hs-esslingen.de/mariadb/repo/10.1/ubuntu trusty main') >> $LOGFILE 2>&1; then
	printf " --> SUCCESSFUL added MariaDB Repository\n"; else printf " --> ERROR - could not add MariaDB Repository - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (apt-get install software-properties-common -y && add-apt-repository cloud-archive:$OSVERSION -y ) >> $LOGFILE 2>&1; then
	printf " --> SUCCESSFUL added $OSVERSION Repository \n"; else printf " --> ERROR - could not add $OSVERSION Repository - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

if (apt-get update) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL updated Package list \n"; else printf " --> ERROR - could not update Package list - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
if (apt-get install python-openstackclient python-pymysql -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL installed Python Clients \n"; else printf " --> ERROR - could not add Python clients - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
printf "
  -----------------------------------
 | #### Done with Base install ##### |
  -----------------------------------\n\n" | tee -a $LOGFILE


${INSTALLPATH}/base/install_mysql.sh $LOGFILE $CONTROLLERIP $INSTALLPATH $OSVERSION
${INSTALLPATH}/base/install_rabbitmq.sh $LOGFILE
${CONFIGPATH}/install_keystone.sh $LOGFILE $CONTROLLERNAME $CONFIGPATH
${CONFIGPATH}/install_glance.sh $LOGFILE $CONTROLLERNAME $CONFIGPATH
${CONFIGPATH}/install_nova.sh $LOGFILE $CONTROLLERNAME $CONTROLLERIP
${CONFIGPATH}/install_neutron.sh $LOGFILE $CONTROLLERNAME $CONTROLLERIP $BUILDDOMAIN $DOMAINSUFFIX $CONFIGPATH
${CONFIGPATH}/install_horizon.sh $LOGFILE $CONTROLLERNAME $CONFIGPATH
${CONFIGPATH}/install_heat.sh $LOGFILE $CONTROLLERNAME $CONFIGPATH
${CONFIGPATH}/install_cinder.sh $LOGFILE $CONTROLLERNAME $CONTROLLERIP $SIO_GW $SIO_PD $SIO_SP $CONFIGPATH
if [ $BASECONFIG = "true" ]; then ${INSTALLPATH}/conf_env.sh $LOGFILE $CONTROLLERNAME $BUILDDOMAIN ; fi 





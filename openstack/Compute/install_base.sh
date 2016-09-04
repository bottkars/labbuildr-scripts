#!/bin/bash
#### Define Colors
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

printf "$green" '############################
##### System Details ####
############################'
printf '\n'

LOCALHOSTNAME=$(hostname)
LOCALIP=$(ifconfig | grep -v 127.0.0.1 | awk '/inet addr/{print substr($2,6)}')
printf '### Hostname: '$LOCALHOSTNAME'\n'
printf '### IP: '$LOCALIP'\n\n'

printf "$green" '############################
##### Controller Details ####
############################'
printf '\n'

echo -n ' Bitte Controller IP eingeben: '
read CONTROLLERIP
echo -n ' Bitte Controller Shortname eingeben: '
read CONTROLLERNAME

printf '### Controller Name: '$CONTROLLERNAME'\n'
printf '### Controller IP: '$CONTROLLERIP'\n\n'

echo $CONTROLLERIP' '$CONTROLLERNAME >> /etc/hosts
printf "$green" '############################
###### Prepare Install #####
############################'
printf '\n'

printf '##### Logs & Permissions #####\n'
mkdir logs
touch ./logs/general.log
touch ./logs/nova.log
touch ./logs/neutron.log
chmod +x install_nova.sh
chmod +x install_neutron.sh


printf '##### Prepare Repos'
#Openstack Liberty Repo
apt-get install software-properties-common -y >> ./logs/general.log 2>&1
add-apt-repository cloud-archive:liberty -y >> ./logs/general.log 2>&1

printf ' ---> done. ##### \n\n'

printf "$green" '#############################
#### Install Basic Tools ####
#############################'
printf '\n'

printf '##### Update Repos '
apt-get update >> ./logs/general.log 2>&1
printf ' --> done\n'

printf '##### Install Python MySQL & Openstack client\n'
apt-get install python-openstackclient python-pymysql -y >> ./logs/general.log 2>&1

printf '###### Basic Install done\n'


./install_nova.sh $LOCALIP $CONTROLLERIP $CONTROLLERNAME
./install_neutron.sh $LOCALIP $CONTROLLERIP $CONTROLLERNAME










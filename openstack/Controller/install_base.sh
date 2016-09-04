#!/bin/bash
#### Define Colors
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

START=$(date +%H:%M:%S)

printf "$green" '############################
##### Get Systemdetails ####
############################'
printf '\n'

LOCALHOSTNAME=$(hostname)
LOCALIP=$(ifconfig | grep -v 127.0.0.1 | awk '/inet addr/{print substr($2,6)}')
printf '### Hostname: '$LOCALHOSTNAME'\n'
printf '### IP: '$LOCALIP'\n\n'


printf "$green" '############################
###### Prepare Install #####
############################'
printf '\n'

printf '##### Logs & Permissions #####\n'
mkdir logs
touch ./logs/general.log
touch ./logs/mysql.log
touch ./logs/rabbitmq.log
touch ./logs/keystone.log
touch ./logs/glance.log
touch ./logs/nova.log
touch ./logs/neutron.log
touch ./logs/cinder.log
touch ./logs/horizon.log
chmod +x install_mysql.sh
chmod +x install_rabbitmq.sh
chmod +x install_keystone.sh
chmod +x install_glance.sh
chmod +x install_nova.sh
chmod +x install_neutron.sh
chmod +x install_cinder.sh
chmod +x install_horizon.sh

printf '##### Prepare Repos'
#MariaDB Repos
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db >> ./logs/mysql.log 2>&1
add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror2.hs-esslingen.de/mariadb/repo/10.1/ubuntu trusty main' >> ./logs/mysql.log 2>&1

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

./install_mysql.sh $LOCALHOSTNAME $LOCALIP 
./install_rabbitmq.sh
./install_keystone.sh $LOCALHOSTNAME
./install_glance.sh $LOCALHOSTNAME $LOCALIP
./install_nova.sh $LOCALHOSTNAME $LOCALIP
./install_neutron.sh $LOCALHOSTNAME $LOCALIP
./install_cinder.sh $LOCALHOSTNAME $LOCALIP
./install_horizon.sh $LOCALHOSTNAME $LOCALIP

printf 'Started at   : '$START
printf '\nFinished at  :'$(date +%H:%M:%S)
printf '\n'









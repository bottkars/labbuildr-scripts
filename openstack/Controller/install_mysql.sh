#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALIP=$2


printf "$green" '############################
###### Install MariaDB #####
#############################'
printf '\n'

### SET PW
debconf-set-selections <<< "mysql-server mysql-server/root_password password Password123!"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password Password123!"

### Install MariaDB 10.1
apt-get install mariadb-server-10.1 -y >> ./logs/mysql.log 2>&1

### Stop Service
service mysql stop >> ./logs/mysql.log 2>&1

### Configure
cp ./configs/my.cnf /etc/mysql/my.cnf
sed -i '/bind-address*/c\bind-address            = '$LOCALIP /etc/mysql/my.cnf

### Start MariaDB-Server
service mysql start >> ./logs/mysql.log 2>&1

printf '### Configure Tables and User \n\n'
#Keystone
mysql -u root --password='Password123!' -e "CREATE DATABASE keystone;"
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'Password123\!';"
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Password123\!';"
#Glance
mysql -u root --password='Password123!' -e "CREATE DATABASE glance;"
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'Password123\!';"
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'Password123\!';"
#Nova
mysql -u root --password='Password123!' -e "CREATE DATABASE nova;"
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'Password123\!';"
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'Password123\!';"
#Neutron
mysql -u root --password='Password123!' -e "CREATE DATABASE neutron;"
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'Password123\!';"
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'Password123\!';"
#Cinder
mysql -u root --password='Password123!' -e "CREATE DATABASE cinder;"	
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'Password123\!';"
mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'Password123\!';" 
#Flush Privileges
mysql -u root --password='Password123!' -e "FLUSH PRIVILEGES;"

### Test ####'
mysql -u root --password='Password123!' -e "SHOW DATABASES;"
mysql -u root --password='Password123!' -e "SELECT user,host FROM mysql.user;"



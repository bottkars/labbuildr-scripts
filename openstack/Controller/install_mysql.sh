#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
LOCALIP=$2


printf " #### Start MariaDB Installation \n"

### SET PW
	printf " ### debconf-set-selections "
		debconf-set-selections <<< "mysql-server mysql-server/root_password password Password123!"
		debconf-set-selections <<< "mysql-server mysql-server/root_password_again password Password123!"
		printf $green " --> done"

### Install MariaDB 10.1
	printf " ### Install Packages "
		if apt-get install mariadb-server-10.1 -y >> /tmp/os_logs/mysql.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not install MariaDB Packages - see /tmp/os_logs/mysql.log"
		fi


### Stop Service
	printf " ### Stop mysqld service \n"
		service mysql stop >> /tmp/os_logs/mysql.log 2>&1

### Configure
	printf " ### Configure Mysql \n"
		cp ./configs/my.cnf /etc/mysql/my.cnf
		sed -i '/bind-address*/c\bind-address            = '$LOCALIP /etc/mysql/my.cnf

### Start MariaDB-Server
	printf " ### Start mysqld service"
		if service mysql start >> /tmp/os_logs/mysql.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not start mysqld service - see /tmp/os_logs/mysql.log"
		fi

	printf ' ### Create Tables'
	if (mysql -u root --password='Password123!' -e "CREATE DATABASE keystone;") >> /tmp/os_logs/mysql.log 2>&1; 	then printf " ## Keystone Database created\n"; 	else printf " --> Could not create Keystone Database - see /tmp/os_logs/mysql.log\n"; fi
	if (mysql -u root --password='Password123!' -e "CREATE DATABASE glance;") >> /tmp/os_logs/mysql.log 2>&1; 		then printf " ## Glance Database created\n"; 		else printf " --> Could not create Glance Database - see /tmp/os_logs/mysql.log\n"; fi
	if (mysql -u root --password='Password123!' -e "CREATE DATABASE nova;") >> /tmp/os_logs/mysql.log 2>&1; 			then printf " ## Nova Database created\n"; 		else printf " --> Could not create Nova Database - see /tmp/os_logs/mysql.log\n"; fi
	if (mysql -u root --password='Password123!' -e "CREATE DATABASE neutron;") >> /tmp/os_logs/mysql.log 2>&1; 		then printf " ## Neutron Database created\n"; 	else printf " --> Could not create Neutron Database - see /tmp/os_logs/mysql.log\n"; fi
	if (mysql -u root --password='Password123!' -e "CREATE DATABASE cinder;") >> /tmp/os_logs/mysql.log 2>&1; 		then printf " ## Cinder Database created\n"; 		else printf " --> Could not create Cinder Database - see /tmp/os_logs/mysql.log\n"; fi
	if (mysql -u root --password='Password123!' -e "CREATE DATABASE heat;") >> /tmp/os_logs/mysql.log 2>&1; 		then printf " ## Heat Database created\n"; 		else printf " --> Could not create Heat Database - see /tmp/os_logs/mysql.log\n"; fi
			
	printf " ### Create SQL User and Permissions "	
		#Keystone
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'Password123\!';"
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Password123\!';"
		#Glance
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'Password123\!';"
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'Password123\!';"
		#Nova
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'Password123\!';"
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'Password123\!';"
		#Neutron
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'Password123\!';"
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'Password123\!';"
		#Cinder
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'Password123\!';"
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'Password123\!';" 
		#Heat
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY 'Password123\!';"
		mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY 'Password123\!';" 
		#Flush PRIVILEGES
		mysql -u root --password='Password123!' -e "FLUSH PRIVILEGES;"
	printf $green " --> done\n" 
printf " #### Finished MariaDB Installation \n"

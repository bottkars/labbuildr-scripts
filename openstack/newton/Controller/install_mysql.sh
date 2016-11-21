#!/bin/bash

LOGFILE=$1
CONTROLLERIP=$2
INSTALLPATH=$3

printf "
  ---------------------------------------
 | #### Start MariaDB Installation ##### |
  ---------------------------------------\n\n" | tee -a $LOGFILE
 
 ### SET PW
printf " ### Prepare Silent install\n" | tee -a $LOGFILE
	if (debconf-set-selections <<< "mysql-server mysql-server/root_password password Password123!" && debconf-set-selections <<< "mysql-server mysql-server/root_password_again password Password123!") >> $LOGFILE 2>&1; then 
		printf " --> SUCCESSFUL set debconf selection \n"; else printf " --> ERROR - Could not set debconf selection - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
	### Install MariaDB 10.1
printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install mariadb-server-10.1 -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed mariadb-server-10.1 \n"; else printf " --> ERROR - could not install mariadb-server-10.1 - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
### Stop Service
printf " ### Configure MariaDB\n" | tee -a $LOGFILE
if (service mysql stop)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - stopped mysql service \n"; else printf " --> ERROR - could not stop mysql service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi	
if ( echo "[mysqld]
	bind-address = $CONTROLLERIP
	default-storage-engine = innodb
	innodb_file_per_table
	max_connections = 4096
	collation-server = utf8_general_ci
	character-set-server = utf8" > /etc/mysql/conf.d/99-openstack.cnf); then printf " --> SUCCESSFUL - created MySQL Config\n"; else printf " --> ERROR - could not creat MySQL Config - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
if (service mysql start)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - started mysql service \n"; else printf " --> ERROR - could not start mysql service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ## Create MariaDB Databases\n"
if (mysql -u root --password='Password123!' -e "CREATE DATABASE keystone;") >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Keystone Database created\n"; 	else printf " --> ERROR Could not create Keystone Database - see $LOGFILE \n" | tee -a $LOGFILE; fi
if (mysql -u root --password='Password123!' -e "CREATE DATABASE glance;") >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Glance Database created\n"; 		else printf " --> ERROR Could not create Glance Database - see $LOGFILE \n" | tee -a $LOGFILE; fi
if (mysql -u root --password='Password123!' -e "CREATE DATABASE nova;") >> $LOGFILE 2>&1; 			then printf " --> SUCCESSFUL Nova Database created\n"; 		else printf " --> ERROR Could not create Nova Database - see $LOGFILE \n" | tee -a $LOGFILE; fi


if (mysql -u root --password='Password123!' -e "CREATE DATABASE nova_api;") >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Nova-Api Database created\n"; 	else printf " --> ERROR Could not create Nova-Api Database - see $LOGFILE \n" | tee -a $LOGFILE; fi
if (mysql -u root --password='Password123!' -e "CREATE DATABASE neutron;") >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Neutron Database created\n"; 	else printf " --> ERROR Could not create Neutron Database - see $LOGFILE \n" | tee -a $LOGFILE; fi
if (mysql -u root --password='Password123!' -e "CREATE DATABASE cinder;") >> $LOGFILE 2>&1; 			then printf " --> SUCCESSFUL Cinder Database created\n"; 		else printf " --> ERROR Could not create Cinder Database - see $LOGFILE \n" | tee -a $LOGFILE; fi
if (mysql -u root --password='Password123!' -e "CREATE DATABASE heat;") >> $LOGFILE 2>&1; 			then printf " --> SUCCESSFUL Heat Database created\n"; 		else printf " --> ERROR Could not create Heat Database - see $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ## Create MariaDB Permissions \n"
if (mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'Password123\!';" &&
	mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Password123\!';") >> $LOGFILE 2>&1
then printf " --> SUCCESSFUL entitled user keystone on Database keystone\n"; 	else printf " --> ERROR Could not entitled user keystone on Database keystone - see $LOGFILE \n" | tee -a $LOGFILE; fi

if (mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'Password123\!';" &&
	mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'Password123\!';") >> $LOGFILE 2>&1
then printf " --> SUCCESSFUL entitled user glance on Database glance\n"; 	else printf " --> ERROR Could not entitled user glance on Database glance - see $LOGFILE \n" | tee -a $LOGFILE; fi

if (mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'Password123\!';" &&
	mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'Password123\!';") >> $LOGFILE 2>&1
then printf " --> SUCCESSFUL entitled user nova on Database nova"; 	else printf " --> ERROR Could not entitled user nova on Database nova - see $LOGFILE \n" | tee -a $LOGFILE; fi	

if (mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'Password123\!';"
	mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'Password123\!';")	>> $LOGFILE 2>&1
then printf " --> SUCCESSFUL entitled user nova on Database nova_api"; 	else printf " --> ERROR Could not entitled user nova on Database nova_api - see $LOGFILE \n" | tee -a $LOGFILE; fi	

if (mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'Password123\!';" &&
	mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'Password123\!';") >> $LOGFILE 2>&1
then printf " --> SUCCESSFUL entitled user neutron on Database neutron\n"; 	else printf " --> ERROR Could not entitled user neutron on Database neutron - see $LOGFILE \n" | tee -a $LOGFILE; fi

if (mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'Password123\!';" &&
	mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'Password123\!';") >> $LOGFILE 2>&1
then printf " --> SUCCESSFUL entitled user cinder on Database cinder\n"; 	else printf " --> ERROR Could not entitled user cinder on Database cinder - see $LOGFILE \n" | tee -a $LOGFILE; fi

if (mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY 'Password123\!';" &&
	mysql -u root --password='Password123!' -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY 'Password123\!';") >> $LOGFILE 2>&1
then printf " --> SUCCESSFUL entitled user heat on Database heat\n"; 	else printf " --> ERROR Could not entitled user heat on Database heat - see $LOGFILE \n" | tee -a $LOGFILE; fi

if (mysql -u root --password='Password123!' -e "FLUSH PRIVILEGES;"); then printf  " --> SUCCESSFUL flushed permissions \n"; 	else printf " --> ERROR Could not flush permissions  - see $LOGFILE \n" | tee -a $LOGFILE; fi

printf "
  ------------------------------------------
 | #### Finished MariaDB Installation ##### |
  ------------------------------------------\n" | tee -a $LOGFILE






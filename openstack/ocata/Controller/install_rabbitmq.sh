#!/bin/bash

LOGFILE=$1

printf "
  ----------------------------------------
 | #### Start RabbitMQ Installation ##### |
  ----------------------------------------\n\n"  | tee -a $LOGFILE
 
	### Install MariaDB 10.1
printf " ## Install Packages\n" | tee -a $LOGFILE
	if (apt-get install rabbitmq-server -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed rabbitmq-server \n"; else printf " --> ERROR - could not install rabbitmq-server - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
printf " ## Configure RabbitMQ \n" | tee -a $LOGFILE
	if (rabbitmq-plugins enable rabbitmq_management) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - enabled RabbitMQ management plugins \n"; else printf " --> ERROR - could not enable RabbitMQ management plugins - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (service rabbitmq-server restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted rabbitmq-server service \n"; else printf " --> ERROR - could not restart rabbitmq-server service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
printf " ### Create Users \n" | tee -a $LOGFILE
	if (rabbitmqctl add_user nova_ctrl Password123!) >> $LOGFILE 2>&1; 				then printf " --> SUCCESSFUL Created user nova_ctrl \n"; 				else printf " ERROR --> Could not create user nova_ctrl - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl add_user nova_compute Password123!) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created user nova_compute \n"; 		else printf " ERROR --> Could not create user nova_compute - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl add_user neutron Password123!) >> $LOGFILE 2>&1; 				then printf " --> SUCCESSFUL Created user neutron \n"; 					else printf " ERROR --> Could not create user neutron - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl add_user neutron_compute Password123!) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created user neutron_compute \n";	else printf " ERROR --> Could not create user neutron_compute - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl add_user cinder Password123!) >> $LOGFILE 2>&1; 					then printf " --> SUCCESSFUL Created user cinder \n"; 					else printf " ERROR --> Could not create user cinder - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl add_user heat Password123!) >> $LOGFILE 2>&1; 					then printf " --> SUCCESSFUL Created user heat \n"; 						else printf " ERROR --> Could not create user heat - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl add_user murano Password123!) >> $LOGFILE 2>&1; 				then printf " --> SUCCESSFUL Created murano heat \n"; 						else printf " ERROR --> Could not create user murano- see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Configure user permissions \n" | tee -a $LOGFILE
	if (rabbitmqctl set_permissions nova_ctrl ".*" ".*" ".*" &&	rabbitmqctl set_user_tags nova_ctrl administrator) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created permissions for user nova_ctrl \n"; else printf " ERROR --> Could not create permissions for user nova_ctrl - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl set_permissions nova_compute ".*" ".*" ".*" &&	rabbitmqctl set_user_tags nova_compute administrator) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created permissions for user nova_compute \n"; else printf " ERROR --> Could not create permissions for user nova_compute - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl set_permissions neutron ".*" ".*" ".*" &&	rabbitmqctl set_user_tags neutron administrator) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created permissions for user neutron \n"; else printf " ERROR --> Could not create permissions for user neutron - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl set_permissions neutron_compute ".*" ".*" ".*" &&	rabbitmqctl set_user_tags neutron_compute administrator) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created permissions for user neutron_compute \n"; else printf " ERROR --> Could not create permissions for user neutron_compute - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl set_permissions cinder ".*" ".*" ".*" &&	rabbitmqctl set_user_tags cinder administrator) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created permissions for user cinder \n"; else printf " ERROR --> Could not create permissions for user cinder - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl set_permissions heat ".*" ".*" ".*" &&	rabbitmqctl set_user_tags heat administrator) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created permissions for user heat \n"; else printf " ERROR --> Could not create permissions for user heat - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if (rabbitmqctl set_permissions murano ".*" ".*" ".*" &&	rabbitmqctl set_user_tags murano administrator) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created permissions for user murano\n"; else printf " ERROR --> Could not create permissions for user murano - see Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf "
  --------------------------------------------
 | #### Finished  RabbitMQ Installation ##### |
  --------------------------------------------\n\n" | tee -a $LOGFILE
	
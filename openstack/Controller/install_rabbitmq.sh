#!/bin/bash
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

printf " #### Start RabbitMQ Installation \n"

### Install 
	printf " ### Install Packages "
		if apt-get install rabbitmq-server -y >> /tmp/os_logs/rabbitmq.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not install RabbitMQ Packages - see /tmp/os_logs/rabbitmq.log"
		fi			

### Configure Management plugins
	printf " ### Configure Management Plugins "
		if rabbitmq-plugins enable rabbitmq_management >> /tmp/os_logs/rabbitmq.log 2>&1; then
			printf $green " --> done"	
		else
			printf $red " --> Could not configure Management Plugins - see /tmp/os_logs/rabbitmq.log"
		fi			

### Restart Service

	printf " ### Start mysqld service"
		if service rabbitmq-server restart >> /tmp/os_logs/rabbitmq.log 2>&1; then
			printf $green " --> done"
		else
			printf $red " --> Could not restart rabbitmq-server service - see /tmp/os_logs/rabbitmq.log"
		fi
	
	printf ' ### Create Users \n'
		if (rabbitmqctl add_user nova_ctrl Password123!) >> /tmp/os_logs/rabbitmq.log 2>&1; 				then printf " ## Created user nova_ctrl \n"; 				else printf " Could not create user nova_ctrl - see /tmp/os_logs/rabbitmq.log\n"; fi
		if (rabbitmqctl add_user nova_compute Password123!) >> /tmp/os_logs/rabbitmq.log 2>&1; 		then printf " ## Created user nova_compute \n"; 		else printf " Could not create user nova_compute - see /tmp/os_logs/rabbitmq.log\n"; fi
		if (rabbitmqctl add_user neutron Password123!) >> /tmp/os_logs/rabbitmq.log 2>&1; 				then printf " ## Created user neutron \n"; 					else printf " Could not create user neutron - see /tmp/os_logs/rabbitmq.log\n"; fi
		if (rabbitmqctl add_user neutron_compute Password123!) >> /tmp/os_logs/rabbitmq.log 2>&1; 	then printf " ## Created user neutron_compute \n";	else printf " Could not create user neutron_compute - see /tmp/os_logs/rabbitmq.log\n"; fi
		if (rabbitmqctl add_user cinder Password123!) >> /tmp/os_logs/rabbitmq.log 2>&1; 					then printf " ## Created user cinder \n"; 					else printf " Could not create user cinder - see /tmp/os_logs/rabbitmq.log\n"; fi
		
		
	printf '### Configure user permissions \n'
		#Nova
		rabbitmqctl set_permissions nova_ctrl ".*" ".*" ".*"
		rabbitmqctl set_user_tags nova_ctrl administrator 
		rabbitmqctl set_permissions nova_compute ".*" ".*" ".*"
		rabbitmqctl set_user_tags nova_compute administrator 
		#Neutron
		rabbitmqctl set_permissions neutron ".*" ".*" ".*"
		rabbitmqctl set_user_tags neutron administrator 
		rabbitmqctl set_permissions neutron_compute ".*" ".*" ".*"
		rabbitmqctl set_user_tags neutron_compute administrator 
		#Cinder 
		rabbitmqctl set_permissions cinder ".*" ".*" ".*"
		rabbitmqctl set_user_tags cinder administrator 
		printf $green " --> done\n"		
		
printf " #### Finished RabbitMQ Installation \n"
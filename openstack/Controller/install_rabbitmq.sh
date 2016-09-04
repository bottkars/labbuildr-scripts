#!/bin/bash
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

printf "$green" '\n#############################
###### Install RabbitMQ ######
##############################'

### Install 
apt-get install rabbitmq-server -y >> ./logs/rabbitmq.log 2>&1

### Configure Management plugins
rabbitmq-plugins enable rabbitmq_management >> ./logs/rabbitmq.log 2>&1

### Restart Service
service rabbitmq-server restart >> ./logs/rabbitmq.log 2>&1


printf '### Create Users and permissions'
{
#Nova
rabbitmqctl add_user nova_ctrl Password123!
rabbitmqctl set_permissions nova_ctrl ".*" ".*" ".*"
rabbitmqctl set_user_tags nova_ctrl administrator 
rabbitmqctl add_user nova_compute Password123!
rabbitmqctl set_permissions nova_compute ".*" ".*" ".*"
rabbitmqctl set_user_tags nova_compute administrator 
#Neutron
rabbitmqctl add_user neutron Password123!
rabbitmqctl set_permissions neutron ".*" ".*" ".*"
rabbitmqctl set_user_tags neutron administrator 
rabbitmqctl add_user neutron_compute Password123!
rabbitmqctl set_permissions neutron_compute ".*" ".*" ".*"
rabbitmqctl set_user_tags neutron_compute administrator 
#Cinder 
rabbitmqctl add_user cinder Password123!
rabbitmqctl set_permissions cinder ".*" ".*" ".*"
rabbitmqctl set_user_tags cinder administrator 
} &>> ./logs/rabbitmq.log
printf '### Rabbitmq installed\n\n\n'
rabbitmqctl list_users

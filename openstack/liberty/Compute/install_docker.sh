#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

printf "\n\n #### Start Docker Installation \n"

	printf " ### Install Pip\n"
		if (apt-get install python-pip -y) >> /tmp/os_logs/nova_docker.log 2>&1; then
			printf " --> Installed Pip\n"
		else
			printf " ERROR --> Installed Pip - see /tmp/os_logs/nova_docker.log\n"
		fi
			
	if (usermod -aG docker nova) >> /tmp/os_logs/nova_docker.log 2>&1; then
		printf " --> Added User docker to group nova\n"
	else
		printf " ERROR --> Could not add User docker to group nova - see /tmp/os_logs/nova_docker.log\n"
	fi

	if (pip install -e git+https://github.com/stackforge/nova-docker#egg=novadocker) >> /tmp/os_logs/nova_docker.log 2>&1; then
		printf " --> Pip installed Docker Repo\n"
	else
		printf " ERROR --> Pip could not install Docker Repo - see /tmp/os_logs/nova_docker.log\n"
	fi
	
	##step into directory
	cd ./src/novadocker
	
	if (git checkout -b stable/liberty origin/stable/liberty) >> /tmp/os_logs/nova_docker.log 2>&1; then
		printf " --> Checked out at origin/stable/liberty \n"
	else
		printf " ERROR  --> Could not checke out at origin/stable/liberty - see /tmp/os_logs/nova_docker.log\n"
	fi
	
	if (python setup.py install) >> /tmp/os_logs/nova_docker.log 2>&1; then
		printf " --> Installed Nova-Docker driver \n"
	else
		printf " ERROR  --> Could not installe Nova-Docker driver - see /tmp/os_logs/nova_docker.log\n"
	fi
	
printf "#### Configure Nova for Docker \n"
	if (sed -i '/compute_driver*/c\compute_driver = novadocker.virt.docker.DockerDriver' /etc/nova/nova-compute.conf ) >> /tmp/os_logs/nova_docker.log 2>&1; then
		printf " --> Configured Nova to use Docker driver\n"
	else
		printf " ERROR --> Could not configure Nova to use Docker driver\n"
	fi 
	
	if (echo "# nova-rootwrap command filters for setting up network in the docker driver
# This file should be owned by (and only-writeable by) the root user

[Filters]
# nova/virt/docker/driver.py: 'ln', '-sf', '/var/run/netns/.*'
ln: CommandFilter, /bin/ln, root" >> /etc/nova/rootwrap.d/docker.filters) >> /tmp/os_logs/nova_docker.log 2>&1; then
		printf " --> Added rootwrap\n"
	else
		printf " ERROR --> Could not add rootwrap - see /tmp/os_logs/nova_docker.log\n"
	fi

printf " #### Restart Service"
if service nova-compute restart >> /tmp/os_logs/nova_docker.log 2>&1; 				then printf " --> Restart Nova-Compute done\n"; 				else printf  " ERROR --> Could not restart Nova-Compute Service - see /tmp/os_logs/nova_docker.log\n";fi


#!/bin/bash

LOGFILE=$1
CONTROLLERNAME=$2
INSTALLPATH=$3
OS_URL="http://$CONTROLLERNAME:35357/v3"
BASECOMMAND="openstack --os-username admin --os-password Password123! --os-project-name admin --os-user-domain-name default --os-project-domain-name default --os-auth-url $OS_URL --os-identity-api-version 3 "

printf "
  ----------------------------------------
 | #### Start Keystone Installation ##### |
  ----------------------------------------\n\n" | tee -a $LOGFILE

printf " ### Install Packages\n" | tee -a $LOGFILE
	if (apt-get install keystone -y) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - installed Keystone Packages\n"; else printf " --> ERROR - could not install keystone Packages - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Configure Keystone \n" | tee -a $LOGFILE
	if (cp ${INSTALLPATH}/configs/keystone.conf /etc/keystone/keystone.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied Keystone.conf file \n"; else printf " --> ERROR - Could not copy Keystone.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 
	if (cp ${INSTALLPATH}/configs/apache2.conf /etc/apache2/apache2.conf) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Copied apache2.conf file \n"; else printf " --> ERROR - Could not copy apache2.conf file - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi 

	sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://keystone:Password123!@'$CONTROLLERNAME'/keystone' /etc/keystone/keystone.conf | tee -a $LOGFILE 2>&1
	sed -i '/ServerName*/c\ServerName '$CONTROLLERNAME /etc/apache2/apache2.conf | tee -a $LOGFILE 2>&1
	sed -i '/Listen 80/c\Listen 88' /etc/apache2/ports.conf | tee -a $LOGFILE 2>&1
	if (su -s /bin/sh -c "keystone-manage db_sync" keystone) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - Populated Keystone Database\n"; else printf " --> ERROR - could not populated Keystone Database - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	
	if (service apache2 restart)  >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL - restarted apache2 service \n"; else printf " --> ERROR - could not restart apache2 service - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	rm -f /var/lib/keystone/keystone.db; printf " --> SUCCESSFUL - Removed Dummy Database \n"

	if ( keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone) >> $LOGFILE 2>&1; 
		then printf " --> SUCCESSFUL - Setup fernet tokens \n"; else printf " --> ERROR - could not setup fernet tokens - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if ( keystone-manage credential_setup --keystone-user keystone --keystone-group keystone) >> $LOGFILE 2>&1; 
		then printf " --> SUCCESSFUL - Setup Fernet Credentials \n"; else printf " --> ERROR - could not setup Fernet Credentials - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi
	if ( keystone-manage bootstrap --bootstrap-password Password123! --bootstrap-admin-url http://$CONTROLLERNAME:35357/v3/ --bootstrap-internal-url http://$CONTROLLERNAME:35357/v3/ --bootstrap-public-url http://$CONTROLLERNAME:5000/v3/ --bootstrap-region-id RegionOne) >> $LOGFILE 2>&1; 
		then printf " --> SUCCESSFUL - Populated Bootstrapped Keystone \n"; else printf " --> ERROR - could not bootstrap Keystone - Logfile: $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Create Keystone Domains \n"
	if ($BASECOMMAND domain create heat --description "Owns users and projects created by heat") >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Keystone Domain Heat \n"; 	else printf " --> ERROR - Could not create Keystone Domain Heat - see $LOGFILE \n" | tee -a $LOGFILE; fi	
printf " ### Create Services \n"
	if ($BASECOMMAND service create --name glance --description "OpenStack Image" image) >> $LOGFILE 2>&1; 					then printf " --> SUCCESSFUL Created Keystone Service Glance (image) \n"; 			else printf " --> ERROR - Could not create Keystone Service Glance (image) - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND service create --name nova --description "OpenStack Compute" compute) >> $LOGFILE 2>&1; 			then printf " --> SUCCESSFUL Created Keystone Service Nova (compute) \n"; 		else printf " --> ERROR - Could not create Keystone Service Nova (compute) - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND service create --name placement --description "OpenStack Placement" placement) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Keystone Service Placement API (placement) \n"; 	else printf " --> ERROR - Could not create Keystone Service Nova Placement API (placement) - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND service create --name neutron --description "OpenStack Networking" network) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Keystone Service Neutron (network) \n"; 	else printf " --> ERROR - Could not create Keystone Service Neutron (network) - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND service create --name cinder --description "OpenStack Block Storage" volume) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Keystone Service Cinder (volume) \n"; 		else printf " --> ERROR - Could not create Keystone Service Cinder (volume) - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND service create --name cinderv2 --description "OpenStack Block Storage" volumev2) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created Keystone Service Cinder (volumev2) \n"; 	else printf " --> ERROR - Could not create Keystone Service Cinder (volumev2) - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND service create --name heat --description "Orchestration" orchestration) >> $LOGFILE 2>&1; 					then printf " --> SUCCESSFUL Created Keystone Service Heat (Orchestration) \n"; 	else printf " --> ERROR - Could not create Keystone Service Heat (Orchestration) - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND service create --name heat-cfn --description "Orchestration"  cloudformation) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Keystone Service Heat-cfn (cloudformation) \n"; 	else printf " --> ERROR - Could not create Keystone Service Heat-cfn (cloudformation) - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND service create --name swift --description "OpenStack Object Storage" object-store) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Keystone Service Swift (object-store) \n"; 	else printf " --> ERROR - Could not create Keystone Service Swift (object-store) - see $LOGFILE \n" | tee -a $LOGFILE; fi	
printf " ### Create Endpoints \n"
	#Glance
	if ($BASECOMMAND endpoint create --region RegionOne image public http://$CONTROLLERNAME:9292) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Glance public endpoint\n"; 	else printf " --> ERROR - Could not create Glance public endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne image internal http://$CONTROLLERNAME:9292) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created Glance internal endpoint\n"; else printf " --> ERROR - Could not create Glance internal endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne image admin http://$CONTROLLERNAME:9292) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Glance admin endpoint\n"; 	else printf " --> ERROR - Could not create Glance admin endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	## Nova
	if ($BASECOMMAND endpoint create --region RegionOne compute public http://$CONTROLLERNAME:8774/v2.1/%\(tenant_id\)s) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Nova public endpoint\n"; 	else printf " --> ERROR - Could not create Nova public endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne compute internal http://$CONTROLLERNAME:8774/v2.1/%\(tenant_id\)s) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Nova internal endpoint\n"; 	else printf " --> ERROR - Could not create Nova internal endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne compute admin http://$CONTROLLERNAME:8774/v2.1/%\(tenant_id\)s) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Nova admin endpoint\n"; 	else printf " --> ERROR - Could not create Nova admin endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	#Nova Placement API
	if ($BASECOMMAND endpoint create --region RegionOne placement public http://$CONTROLLERNAME:8778) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Nova Placement API public endpoint\n"; 	else printf " --> ERROR - Could not create Nova Placement API public endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne placement admin http://$CONTROLLERNAME:8778) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Nova Placement API admin endpoint\n"; 	else printf " --> ERROR - Could not create Nova Placement API admin endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne placement internal http://$CONTROLLERNAME:8778) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Nova Placement API internal endpoint\n"; 	else printf " --> ERROR - Could not create Nova Placement API internal endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	## Neutron
	if ($BASECOMMAND endpoint create --region RegionOne network public http://$CONTROLLERNAME:9696) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Neutron public endpoint\n"; 	else printf " --> ERROR - Could not create Neutron public endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne network internal http://$CONTROLLERNAME:9696) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created Neutron internal endpoint\n"; 	else printf " --> ERROR - Could not create Neutron internal endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne network admin http://$CONTROLLERNAME:9696) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Neutron admin endpoint\n"; 	else printf " --> ERROR - Could not create Neutron admin endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	## Cinder
	if ($BASECOMMAND endpoint create --region RegionOne volume public http://$CONTROLLERNAME:8776/v1/%\(tenant_id\)s) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Cinder public endpoint\n"; 		else printf " --> ERROR - Could not create Cinder public endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne volume internal http://$CONTROLLERNAME:8776/v1/%\(tenant_id\)s) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Cinder internal endpoint\n";	 	else printf " --> ERROR - Could not create Cinder internal endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne volume admin http://$CONTROLLERNAME:8776/v1/%\(tenant_id\)s) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Cinder admin endpoint\n"; 		else printf " --> ERROR - Could not create Cinder admin endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne volumev2 public http://$CONTROLLERNAME:8776/v2/%\(tenant_id\)s) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Cinderv2 public endpoint\n"; 	else printf " --> ERROR - Could not create Cinderv2 public endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne volumev2 internal http://$CONTROLLERNAME:8776/v2/%\(tenant_id\)s) >> $LOGFILE 2>&1;then printf " --> SUCCESSFUL Created Cinderv2 internal endpoint\n"; else printf " --> ERROR - Could not create Cinderv2 internal endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne volumev2 admin http://$CONTROLLERNAME:8776/v2/%\(tenant_id\)s) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Cinderv2 admin endpoint\n"; 	else printf " --> ERROR - Could not create Cinderv2 admin endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	## Heat
	if ($BASECOMMAND endpoint create --region RegionOne orchestration public http://$CONTROLLERNAME:8004/v1/%\(tenant_id\)s) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created Heat Orchestration public endpoint\n"; 	else printf " --> ERROR - Could not create Heat Orchestration public endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne orchestration internal http://$CONTROLLERNAME:8004/v1/%\(tenant_id\)s) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created Heat Orchestration internal endpoint\n"; 	else printf " --> ERROR - Could not create Heat Orchestration internal endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne orchestration admin http://$CONTROLLERNAME:8004/v1/%\(tenant_id\)s) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created Heat Orchestration admin endpoint\n"; 	else printf " --> ERROR - Could not create Heat Orchestration admin endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne cloudformation public http://$CONTROLLERNAME:8000/v1) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Heat Cloudformation public endpoint\n"; 	else printf " --> ERROR - Could not create Heat Cloudformation public endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne cloudformation internal http://$CONTROLLERNAME:8000/v1) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Heat Cloudformation  internal endpoint\n"; 	else printf " --> ERROR - Could not create Heat Cloudformation internal endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne cloudformation admin http://$CONTROLLERNAME:8000/v1) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Heat Cloudformation admin endpoint\n"; 	else printf " --> ERROR - Could not create Heat Cloudformation admin endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	## Neutron
	if ($BASECOMMAND endpoint create --region RegionOne object-store public http://$CONTROLLERNAME:8080/v1/AUTH_%\(tenant_id\)s) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Swift public endpoint\n"; 	else printf " --> ERROR - Could not create Swift public endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne object-store internal http://$CONTROLLERNAME:8080/v1/AUTH_%\(tenant_id\)s) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Created Swift internal endpoint\n"; 	else printf " --> ERROR - Could not create Swift internal endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND endpoint create --region RegionOne object-store admin http://$CONTROLLERNAME:8080/v1) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Swift admin endpoint\n"; 	else printf " --> ERROR - Could not create Swift admin endpoint - see $LOGFILE \n" | tee -a $LOGFILE; fi	
printf " ### Create Projects \n"		
	if ($BASECOMMAND project create --domain default --description "Service Project" service ) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Project service\n"; 	else printf " ERROR --> Could not create Project service \n"; fi
printf " ### Create Roles \n"
	if ($BASECOMMAND role create user ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created Role user\n"; 		else printf " --> ERROR - Could not create role user \n"; fi
	if ($BASECOMMAND role create HeatStackOwner ) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Role HeatStackOwner\n"; 	else printf " --> ERROR - Could not create role HeatStackOwner \n"; fi
	if ($BASECOMMAND role create heat_stack_user ) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created Role heat_stack_user\n"; 	else printf " --> ERROR - Could not create role heat_stack_user \n"; fi
printf " ### Create Users \n"		
	if ($BASECOMMAND user create --domain default --project service --password Password123! glance ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created User glance\n"; 	else printf " --> ERROR - Could not create User glance  - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND user create --domain default --project service --password Password123! nova ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created User nova\n"; 	else printf " --> ERROR - Could not create User nova  - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND user create --domain default --project service --password Password123! placement ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created User placement \n"; 	else printf " --> ERROR - Could not create User placement  - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND user create --domain default --project service --password Password123! neutron ) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created User neutron\n"; else printf " --> ERROR - Could not create User neutron  - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND user create --domain default --project service --password Password123! cinder ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created User cinder\n"; 	else printf " --> ERROR - Could not create User cinder  - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND user create --domain default --project service --password Password123! heat ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created User heat\n"; 		else printf " --> ERROR - Could not create User heat - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND user create --domain default --project service --password Password123! swift ) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Created User swift\n"; 		else printf " --> ERROR - Could not create User swift - see $LOGFILE \n" | tee -a $LOGFILE; fi
	# In Domain Heat
	if ($BASECOMMAND user create --domain heat --password Password123! HeatDomainAdmin ) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Created User HeatDomainAdmin in Domain heat\n"; 	else printf " --> ERROR - Could not create User HeatDomainAdmin in Domain heat - see $LOGFILE \n" | tee -a $LOGFILE; fi

printf " ### Map User to Role and Project \n"
	if ($BASECOMMAND role add --project admin --user admin admin) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Mapped user admin to project admin and role admin \n"; 		else printf " --> ERROR - Could not map user admin to project admin and role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND role add --project admin --user admin HeatStackOwner) >> $LOGFILE 2>&1; 		then printf " --> SUCCESSFUL Mapped user admin to project admin and role HeatStackOwner \n"; 	else printf " --> ERROR - Could not map user admin to project admin and role HeatStackOwner - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND role add --project service --user glance admin) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Mapped user glance to project service and role admin \n"; 		else printf " --> ERROR - Could not map user glance to project service and role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND role add --project service --user nova admin) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Mapped user nova to project service and role admin \n"; 	else printf " --> ERROR - Could not map user nova to project service and role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND role add --project service --user placement admin) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Mapped user placement to project service and role admin \n"; 	else printf " --> ERROR - Could not map user placement to project service and role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND role add --project service --user neutron admin) >> $LOGFILE 2>&1; then printf " --> SUCCESSFUL Mapped user neutron to project service and role admin \n"; else printf " --> ERROR - Could not map user neutron to project service and role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND role add --project service --user cinder admin) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Mapped user cinder to project service and role admin \n"; 		else printf " --> ERROR - Could not map user cinder to project service and role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND role add --project service --user heat admin) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Mapped user heat to project service and role admin \n"; 		else printf " --> ERROR - Could not map user heat to project service and role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	if ($BASECOMMAND role add --project service --user swift admin) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Mapped user swift to project service and role admin \n"; 		else printf " --> ERROR - Could not map user swift to project service and role admin - see $LOGFILE \n" | tee -a $LOGFILE; fi
	# In Domain heat
	if ($BASECOMMAND role add --domain heat --user HeatDomainAdmin admin) >> $LOGFILE 2>&1; 	then printf " --> SUCCESSFUL Mapped user HeatDomainAdmin to role admin in Domain Heat \n"; else printf " --> ERROR - Could not map user HeatDomainAdmin to role admin in Domain Heat - see $LOGFILE \n" | tee -a $LOGFILE; fi
printf "
  -------------------------------------------
 | #### Finished Keystone Installation ##### |
  -------------------------------------------\n\n" | tee -a $LOGFILE	
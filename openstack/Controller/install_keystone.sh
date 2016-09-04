#!/bin/bash

#### Define Env
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'

LOCALHOSTNAME=$1
os_url=http://$LOCALHOSTNAME:35357/v3
os_token=ADMINTOKEN

printf "$green" '############################
###### Install Keystone #####
#############################'
printf '\n'

### Install
apt-get install keystone apache2 libapache2-mod-wsgi -y >> ./logs/keystone.log 2>&1

### Stop Keystone service'
service keystone stop >> ./logs/keystone.log 2>&1

### Disable Keystone Service
echo "manual" > /etc/init/keystone.override

printf '### Configure Keystone and Apache '
cp ./configs/keystone.conf /etc/keystone/keystone.conf
cp ./configs/apache2.conf /etc/apache2/apache2.conf
cp ./configs/wsgi-keystone.conf /etc/apache2/sites-available/wsgi-keystone.conf
sed -i '/admin_token*/c\admin_token = '$os_token /etc/keystone/keystone.conf
sed -i '/connection = mysql+pymysql:*/c\connection = mysql+pymysql://keystone:Password123!@'$LOCALHOSTNAME'/keystone' /etc/keystone/keystone.conf
sed -i '/ServerName*/c\ServerName '$LOCALHOSTNAME /etc/apache2/apache2.conf
sed -i '/Listen 80/c\Listen 88' /etc/apache2/ports.conf

### Populate Database
su -s /bin/sh -c "keystone-manage db_sync" keystone >> ./logs/keystone.log 2>&1

### Enable vHost
ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled

### Restart Apache2
service apache2 restart >> ./logs/keystone.log 2>&1

### Remove Dummy Database
rm -f /var/lib/keystone/keystone.db


printf "$green" '############################
###### Configure Keystone #####
#############################'
printf '\n'

{
#Create Keystone Services
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 service create --name keystone --description "OpenStack Identity" identity
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 service create --name glance --description "OpenStack Image service" image
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 service create --name nova --description "OpenStack Compute" compute
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 service create --name neutron --description "OpenStack Networking" network
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 service create --name cinder --description "OpenStack Block Storage" volume
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 service create --name cinderv2 --description "OpenStack Block Storage" volumev2

#Create Endpoints
## Keystone
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne identity public http://$LOCALHOSTNAME:5000/v2.0
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne identity internal http://$LOCALHOSTNAME:5000/v2.0
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne identity admin http://$LOCALHOSTNAME:35357/v2.0
## Glance
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne image public http://$LOCALHOSTNAME:9292
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne image internal http://$LOCALHOSTNAME:9292
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne image admin http://$LOCALHOSTNAME:9292
## Nova
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne compute public http://$LOCALHOSTNAME:8774/v2/%\(tenant_id\)s
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne compute internal http://$LOCALHOSTNAME:8774/v2/%\(tenant_id\)s
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne compute admin http://$LOCALHOSTNAME:8774/v2/%\(tenant_id\)s
## Neutron
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne network public http://$LOCALHOSTNAME:9696
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne network internal http://$LOCALHOSTNAME:9696
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne network admin http://$LOCALHOSTNAME:9696
## Cinder
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne volume public http://$LOCALHOSTNAME:8776/v1/%\(tenant_id\)s
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne volume internal http://$LOCALHOSTNAME:8776/v1/%\(tenant_id\)s
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne volume admin http://$LOCALHOSTNAME:8776/v1/%\(tenant_id\)s
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne volumev2 public http://$LOCALHOSTNAME:8776/v2/%\(tenant_id\)s
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne volumev2 internal http://$LOCALHOSTNAME:8776/v2/%\(tenant_id\)s
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 endpoint create --region RegionOne volumev2 admin http://$LOCALHOSTNAME:8776/v2/%\(tenant_id\)s

#Create Projects
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 project create --domain default --description "Admin Project" admin
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 project create --domain default --description "Service Project" service

#Create Roles
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 role create admin

#Create Users
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 user create --domain default --password Password123! admin
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 user create --domain default --password Password123! glance
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 user create --domain default --password Password123! nova
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 user create --domain default --password Password123! neutron
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 user create --domain default --password Password123! cinder
		
#Map User-Role-Project
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 role add --project admin --user admin admin
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 role add --project service --user glance admin
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 role add --project service --user nova admin
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 role add --project service --user neutron admin
openstack --os-url $os_url --os-token=$os_token --os-identity-api-version 3 role add --project service --user cinder admin
} &>> ./logs/keystone.log

#Undo Admin-Token
sed -i '/admin_token*/c\#admin_token = '$os_token /etc/keystone/keystone.conf

#Test
openstack --os-auth-url http://$LOCALHOSTNAME:35357/v3 --os-project-domain-id default --os-user-domain-id default --os-project-name admin --os-username admin --os-auth-type password --os-password Password123! token issue





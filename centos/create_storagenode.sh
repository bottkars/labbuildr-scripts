#!/bin/bash
# storagenode creation script v1.0

echo "n
p
1


w
"|fdisk /dev/sdb
mkfs.ext3 /dev/sdb1
mkdir /mnt/aftd1
mount /dev/sdb1 /mnt/aftd1

tar xzfv /mnt/hgfs/Sources/Networker/nw9007_linux_x86_64.tar.gz -C /tmp/
yum localinstall --nogpgcheck -y /tmp/linux_x86_64/lgtoclnt-9.0.0.7-1.x86_64.rpm
yum localinstall --nogpgcheck -y /tmp/linux_x86_64/lgtonode-9.0.0.7-1.x86_64.rpm
yum install -y samba
/etc/init.d/networker start


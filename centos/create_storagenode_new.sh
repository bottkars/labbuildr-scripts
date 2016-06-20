#!/bin/bash
# storagenode creation script v1.0
## do not delete whitespace in fdisk function

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -n|--nwver)
    NWVERSION="$2"
    shift # past argument
    ;;
    -d|--device)
    DEVICE="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo Networker Version  = "${NWVERSION}"
echo Storage Device    = "${DEVICE}"

echo "creating Partition /dev/${DEVICE}1 on ${DEVICE}"

echo "n
p
1


w
"|fdisk /dev/${DEVICE}
mkfs.ext3 /dev/${DEVICE}1
mkdir /mnt/aftd1
echo "Mounting device /dev/${DEVICE}1 to /mnt/aftd1"
mount /dev/${DEVICE}1 /mnt/aftd1
pause

tar xzfv /mnt/hgfs/Sources/Networker/${NWVERSION}_linux_x86_64.tar.gz -C /tmp/
yum localinstall --nogpgcheck -y /tmp/linux_x86_64/lgtoclnt-*.x86_64.rpm
yum localinstall --nogpgcheck -y /tmp/linux_x86_64/lgtonode-*.x86_64.rpm
yum install -y samba
/etc/init.d/networker start
/bin/cp --force  /mnt/hgfs/Scripts/centos/smb.conf.aftd1 /etc/samba/smb.conf
systemctl restart smb
(echo 'Password123!'; echo 'Password123!') | smbpasswd -a root -s
smbpasswd -e root

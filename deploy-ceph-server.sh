#!/usr/bin/bash

# get /etc/ceph to ensure it is present
if [ ! -d /etc/ceph ]; then
  echo "Ceph not properly installed. Exiting."
  exit 1
fi

cp -R /vagrant/ceph/* /etc/ceph
cp /vagrant/ceph-bootstrap-osd.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring

for disk in $(lsblk -dno NAME,TYPE | grep -w disk | awk '{print $1}'); do
  partitions=$(lsblk -no NAME | grep "${disk}[0-9]")
  if [ -z "$partitions" ]; then
    osd_disk="$disk"
  fi
done

echo "Raw disk: $osd_disk"

# get free disk: no partition, no swap
ceph-volume lvm create --data /dev/$osd_disk

ls /var/lib/ceph/osd | grep ceph- > /tmp/osd-list
osd_id=$(cat /tmp/osd-list | awk -F- '{print $2}')
systemctl enable --now ceph-osd@$osd_id

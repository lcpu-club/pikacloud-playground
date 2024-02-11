#!/usr/bin/bash

# get /etc/ceph to ensure it is present
if [ ! -d /etc/ceph ]; then
  echo "Ceph not properly installed. Exiting."
  exit 1
fi

cp -R /vagrant/ceph/* /etc/ceph
cp /vagrant/ceph-bootstrap-osd.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring

ceph-volume lvm create --data /dev/sdb

ls /var/lib/ceph/osd | grep ceph- > /tmp/osd-list
osd_id=$(cat /tmp/osd-list | awk -F- '{print $2}')
systemctl enable --now ceph-osd@$osd_id
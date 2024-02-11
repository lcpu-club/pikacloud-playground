#!/usr/bin/bash

# get /etc/ceph to ensure it is present
if [ ! -d /etc/ceph ]; then
  echo "Ceph not properly installed. Exiting."
  exit 1
fi

cp -R /vagrant/ceph/* /etc/ceph

ceph -s
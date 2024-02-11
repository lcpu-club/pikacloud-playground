#!/usr/bin/bash

# get /etc/ceph to ensure it is present
if [ ! -d /etc/ceph ]; then
  echo "Ceph not properly installed. Exiting."
  exit 1
fi

export uuid=$(uuidgen)

echo "[global]" > /etc/ceph/ceph.conf
echo "fsid = $uuid" >> /etc/ceph/ceph.conf
echo "mon_initial_members = mgt" >> /etc/ceph/ceph.conf
echo "mon_host = 192.168.56.10" >> /etc/ceph/ceph.conf
echo "public_network = 192.168.56.0/24" >> /etc/ceph/ceph.conf

ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring

sudo chown ceph:ceph /tmp/ceph.mon.keyring
monmaptool --create --add mgt 192.168.56.10 --fsid $uuid /tmp/monmap

mkdir /var/lib/ceph/mon/ceph-mgt
chown ceph:ceph /var/lib/ceph/mon/ceph-mgt

sudo -u ceph ceph-mon --cluster ceph --mkfs -i mgt --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring

echo "auth_cluster_required = cephx" >> /etc/ceph/ceph.conf
echo "auth_service_required = cephx" >> /etc/ceph/ceph.conf
echo "auth_client_required = cephx" >> /etc/ceph/ceph.conf
echo "osd_pool_default_size = 3" >> /etc/ceph/ceph.conf
echo "osd_pool_default_min_size = 2" >> /etc/ceph/ceph.conf
echo "osd_pool_default_pg_num = 333" >> /etc/ceph/ceph.conf
echo "osd_crush_chooseleaf_type = 1" >> /etc/ceph/ceph.conf

systemctl enable --now ceph-mon@mgt

ceph -s

mkdir /vagrant/ceph
cp /etc/ceph/ceph.client.admin.keyring /vagrant/ceph
cp /etc/ceph/ceph.conf /vagrant/ceph

mkdir /var/lib/ceph/mgr/ceph-mgt
ceph auth get-or-create mgr.mgt mon 'allow profile mgr' osd 'allow *' mds 'allow *' > /var/lib/ceph/mgr/ceph-mgt/keyring
chown -R ceph:ceph /var/lib/ceph/mgr/ceph-mgt
ceph-mgr -i mgt
systemctl enable --now ceph-mgr@mgt

cp /var/lib/ceph/bootstrap-osd/ceph.keyring /vagrant/ceph-bootstrap-osd.keyring

echo "Ceph MGR UUID: $uuid" >> /vagrant/installation-report.txt
#!/bin/sh

if [ ! -d /tmp/vagrant-cache/ ]; then
  mkdir -p /tmp/vagrant-cache/
fi

chmod 777 /tmp/vagrant-cache/

# change source to pku mirror
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=https://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.pku.edu.cn/rocky|g' \
    -i.bak \
    /etc/yum.repos.d/rocky-extras.repo \
    /etc/yum.repos.d/rocky.repo

# install some basic tools
dnf groupinstall -y "Development Tools" "Container Management" "System Tools"
dnf config-manager --set-enabled crb
dnf install epel-release
crb enable

# change source to pku mirror
sudo sed -e 's|^metalink=|#metalink=|g' \
         -e 's|^#baseurl=https\?://download.fedoraproject.org/pub/epel/|baseurl=https://mirrors.pku.edu.cn/epel/|g' \
         -e 's|^#baseurl=https\?://download.example/pub/epel/|baseurl=https://mirrors.pku.edu.cn/epel/|g' \
         -i.bak \
         /etc/yum.repos.d/epel.repo

# install some basic tools
dnf update -y

# disbale selinux
dnf install -y centos-release-ceph-reef
dnf install -y grubby ceph postgresql-server glibc-all-langpacks
dnf install -y python3-pip python3-devel postgresql-devel
pip3 install --upgrade pip
pip install patroni[psycopg3,etcd3]
dnf install -y haproxy keepalived
grubby --update-kernel ALL --args selinux=0

# disable firewalld
systemctl disable --now firewalld

# set ntp server to cn.ntp.org.cn
sed -e 's|2.rocky.pool.ntp.org|cn.ntp.org.cn|g' \
    -i.bak \
    /etc/chrony.conf

# enable chronyd
systemctl enable --now chronyd

# set timezone to Asia/Shanghai
timedatectl set-timezone Asia/Shanghai
timedatectl set-local-rtc 0

# set hosts
echo "192.168.56.10 mgt" >> /etc/hosts
echo "192.168.56.11 server1" >> /etc/hosts
echo "192.168.56.12 server2" >> /etc/hosts
echo "192.168.56.13 server3" >> /etc/hosts
echo "192.168.56.21 client1" >> /etc/hosts
echo "192.168.56.22 client2" >> /etc/hosts

echo "StrictHostKeyChecking accept-new" >> /etc/ssh/ssh_config

if [ ! -d /root/.ssh/ ]; then
  mkdir -p /root/.ssh/
fi

cp /vagrant/insecure_private_key /root/.ssh/id_rsa
cp /home/vagrant/.ssh/authorized_keys /root/.ssh/authorized_keys
chmod 600 /root/.ssh/id_rsa

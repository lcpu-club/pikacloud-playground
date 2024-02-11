#!/usr/bin/bash

rm -rf cluster-shared/insecure_private_key

echo "restarting the cluster to disable selinux..."

vagrant halt
vagrant up

echo "Install finished. Please check the installation report for details."

cat cluster-shared/installation-report.txt
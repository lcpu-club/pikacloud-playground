#!/usr/bin/bash

postgresql-setup --initdb

systemctl enable postgresql
systemctl start postgresql

# Set the password for the postgres user
sudo -u postgres createuser --superuser vmdriver

# Generate the password for the vmdriver user, only with numbers and letters
vmdriver_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# Set the password for the vmdriver user
sudo -u postgres psql -c "ALTER USER vmdriver WITH PASSWORD '$vmdriver_password'"
echo "vmdriver password: $vmdriver_password"

echo "PostgreSQL installed and configured at 192.168.56.10 with the vmdriver user and the following password: $vmdriver_password" >> /vagrant/installation-report.txt
echo "vmdriver password: $vmdriver_password" > /root/vmdriver_password.txt

# Allow the vmdriver user to connect to the database from any IP address
echo "host all vmdriver 192.168.56.0/24 md5" >> /var/lib/pgsql/data/pg_hba.conf

echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf
echo "max_connections = 100" >> /var/lib/pgsql/data/postgresql.conf
echo "superuser_reserved_connections = 3" >> /var/lib/pgsql/data/postgresql.conf

systemctl restart postgresql
#!/usr/bin/bash
SERVER_NUM=$(ip addr | grep -oP "192.168.56.1\K\d+")
IP_ADDR=$(ip addr | grep -o '192.168.56.1[0-9]')

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

cat << EOF > /etc/patroni.yml
scope: postgres
namespace: /db/
name: server-${SERVER_NUM}

restapi:
  listen: ${IP_ADDR}:8008
  connect_address: ${IP_ADDR}:8008

etcd:
  hosts: 192.168.56.10:2379, 192.168.56.11:2379, 192.168.56.12:2379, 192.168.56.13:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 md5
  - host replication replicator 192.168.56.10/0 md5
  - host replication replicator 192.168.56.11/0 md5
  - host replication replicator 192.168.56.12/0 md5
  - host replication replicator 192.168.56.13/0 md5
  - host all all 0.0.0.0/0 md5
  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb

postgresql:
  listen: ${IP_ADDR}:5432
  connect_address: ${IP_ADDR}:5432
  data_dir: /var/lib/pgsql/data
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: vmdriver
      password: ${vmdriver_password}
    superuser:
      username: vmdriver
      password: ${vmdriver_password}
  parameters:
          unix_socket_directories: '.'

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
EOF

# mkdir -p /var/lib/pgsql/data/patroni/
# chown -R postgres:postgres /var/lib/pgsql/data/patroni
# chmod -R 700 /var/lib/pgsql/data/patroni
# chmod 700 /home/vagrant

cat << EOF > /etc/systemd/system/patroni.service
[Unit]
Description=Runners to orchestrate a high-availability PostgreSQL
After=syslog.target network.target

[Service]
Type=simple

User=postgres
Group=postgres

ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ

EOF

cat <<EOF > /etc/haproxy/haproxy.cfg
global
    maxconn 100

defaults
    log global
    mode tcp
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

frontend patroni-prod
        mode tcp
        maxconn 5000
        bind *:5432
        default_backend patroni_servers


backend patroni_servers
        mode tcp
        option httpchk OPTIONS /leader
        http-check expect status 200
        default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions

        server mgt 192.168.56.10:5432 maxconn 100 check port 8008
        server server-1 192.168.56.11:5432 maxconn 100 check port 8008

listen postgres
    bind *:5000
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server mgt 192.168.56.10:5432 maxconn 100 check port 8008
    server server-1 192.168.56.11:5432 maxconn 100 check port 8008
EOF

cat <<EOF > /etc/keepalived/keepalived.conf
vrrp_script chk_haproxy {
script "/usr/bin/killall -0 haproxy"
    interval 2
    weight 2


}

vrrp_instance VI_1 {
interface eth0
    virtual_router_id 51


    state BACKUP
    priority 101

    virtual_ipaddress {
    10.0.2.15
    }
  track_script {
  chk_haproxy
  }


}
EOF

systemctl restart postgresql
systemctl start keepalived
# systemctl start patroni
# sudo -u postgres /usr/local/bin/patroni /etc/patroni.yml &
# pg_ctl -D /var/lib/pgsql/data/patroni/ -l logfile start &

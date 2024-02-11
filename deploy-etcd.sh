#!/usr/bin/bash

echo "Deploying etcd..."

ETCD_VER=v3.5.12

# choose either URL
MIRROR_URL=https://mirrors.huaweicloud.com/etcd/
DOWNLOAD_URL=${MIRROR_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

/tmp/etcd-download-test/etcd --version
/tmp/etcd-download-test/etcdctl version
/tmp/etcd-download-test/etcdutl version

mv /tmp/etcd-download-test/etc* /usr/bin/

if [ ! -d /var/lib/etcd ]; then
    mkdir -p /var/lib/etcd
fi

cat << EOF > /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd

[Service]
Type=notify
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/usr/bin/etcd --name pkucloud \
    --data-dir /var/lib/etcd
    --–listen-client-urls http://0.0.0.0:2379

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
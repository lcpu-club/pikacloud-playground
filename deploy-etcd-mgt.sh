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

# workaround for selinux
restorecon -rv /usr/bin

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

# https://www.zhaowenyu.com/etcd-doc/ops/etcd-install-shell.html
# https://blog.csdn.net/lengyue1084/article/details/116090035
# https://blog.csdn.net/weixin_42216109/article/details/113617833
# ,pkucloud-server-2=http://192.168.56.12:2380,pkucloud-server-3=http://192.168.56.13:2380
ExecStart=/usr/bin/etcd --name mgt \
    --data-dir /var/lib/etcd \
    --listen-peer-urls="http://192.168.56.10:2380" \
    --listen-client-urls="http://localhost:2379,http://192.168.56.10:2379" \
    --initial-advertise-peer-urls="http://192.168.56.10:2380" \
    --initial-cluster mgt=http://192.168.56.10:2380,server-1=http://192.168.56.11:2380,server-2=http://192.168.56.12:2380,server-3=http://192.168.56.13:2380 \
    --initial-cluster-state=new \
    --initial-cluster-token=etcd-cluster-1 \
    --advertise-client-urls="http://192.168.56.10:2379" \
    --enable-v2=true


[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd
systemctl start etcd &



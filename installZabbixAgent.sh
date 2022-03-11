#!/usr/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "What is your zabbix server address: "
read server
config=/usr/local/etc/zabbix_agentd.conf
echo "Please type your hostname(used in zabbix config file): "
read hostname
hostname=${hostname// /-}

wget https://cdn.zabbix.com/zabbix/sources/oldstable/3.0/zabbix-3.0.32.tar.gz
tar -zxvf zabbix-3.0.32.tar.gz
chown -R root:root zabbix-3.0.32
cd zabbix-3.0.32

addgroup --system --quiet zabbix
adduser --quiet --system --disabled-login --ingroup zabbix --home /var/lib/zabbix --no-create-home zabbix
./configure --enable-agent
make install

sed -i "s/127.0.0.1/$server/g" $config
sed -i "s/Zabbix server/$hostname/g" $config


serviceConfig="[Unit]
Description=Zabbix Agent
After=syslog.target network.target network-online.target
Wants=network.target network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/zabbix_agentd -c /usr/local/etc/zabbix_agentd.conf
RemainAfterExit=yes
PIDFile=/var/run/zabbix/zabbix_agentd.pid

[Install]
WantedBy=multi-user.target"

echo "$serviceConfig" > /etc/systemd/system/zabbix_agentd.service
systemctl daemon-reload
systemctl start zabbix_agentd.service
systemctl enable zabbix_agentd.service

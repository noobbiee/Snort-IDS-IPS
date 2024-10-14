#! /bin/bash

# exit script on error
set -e

#check if the script is run as root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

ip link set dev eth0 promisc on
if ethtool -k eth0 | grep -q 'generic-receive-offload: off'; then
	echo "generic-receive-offload is off"
else
	ethtool -K eth0 gro off
fi



-- create a new snort systemd file to put the interface in promisc mode when snort starts

touch /etc/systemd/system/snort3-nic.service

cat <<EOF > /etc/systemd/system/snort3-nic.service
[Unit]
Description=Set Snort 3 NIC in promiscuous mode and Disable GRO, LRO on boot
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ip link set dev eth0 promisc on
ExecStart=/usr/sbin/ethtool -K eth0 gro off lro off
TimeoutStartSec=0
RemainAfterExit=Yes

[Install]
WantedBy=default.target
EOF
systemctl daemon-reload
systemctl start snort3-nic.service
systemctl enable snort3-nic.service

# create a new directory to store the rules file
mkdir /usr/local/etc/rules
cd /usr/local/etc/rules
wget -qo- https://www.snort.org/downloads/community/snort3-community-rules.tar.gz
tar -xzf snort3-community-rules.tar.gz

echo "open the configuration file in the 

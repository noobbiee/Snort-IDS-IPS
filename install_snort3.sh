#! /bin/bash

# Exit script on any error
set -e

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Update System and Install Dependencies
echo "Updating system and installing required packages..."
apt-get update
apt-get upgrade -y
apt-get install -y build-essential libpcre3-dev libdumbnet-dev \
bison flex zlib1g-dev liblzma-dev openssl libssl-dev libnghttp2-dev \
autoconf libtool libpcap-dev libpq-dev libsqlite3-dev \
libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0 hwloc libhwloc-dev \
libhyperscan-dev libgoogle-perftools-dev uuid-dev libunwind-dev asciidoc w3m cmake

# Install LuaJIT from source
echo "Installing LuaJIT from source..."
cd /usr/src
rm -rf luajit
git clone https://luajit.org/git/luajit.git
cd luajit
make && make install PREFIX=/usr/local
# Install luajit into the /usr/local instead of default paths
ldconfig
echo "LuaJIT installed successfully."

# Install DAQ
echo "Installing DAQ..."
apt-get install libmnl-dev
cd /usr/src
rm -rf libdaq
git clone https://github.com/snort3/libdaq.git
cd libdaq
./bootstrap
./configure --enable-nfq-module
make
make install
ldconfig
echo "DAQ installed successfully."

# Download and Compile Snort
echo "Downloading and compiling Snort..."
cd /usr/src
rm -rf snort3
git clone https://github.com/snort3/snort3.git
cd snort3
mkdir build
cd build

# Configure Snort using CMake
echo "Configuring Snort using CMake..."
cmake .. -Wno-dev
make
make install

# Check if Snort was installed successfully
if ! command -v snort &> /dev/null
then
    echo "Snort could not be installed."
    exit 1
fi


# Create Configuration Files
echo "Creating basic Snort configuration files..."
mkdir -p /etc/snort /etc/snort/rules /var/log/snort

# Ask for user input for HOME_NET configuration
read -p "Enter your HOME_NET (e.g., '192.168.1.0/24', 'any'): " HOME_NET_INPUT
HOME_NET=${HOME_NET_INPUT:-"any"} # Default to 'any' if input is empty

# Create a basic snort.lua file
cat <<EOF > /etc/snort/snort.lua
-- Set your HOME_NET and EXTERNAL_NET variables
HOME_NET = "$HOME_NET"
EXTERNAL_NET = "any"

-- Include your Snort rules here
include 'snort_defaults.lua'
include 'file_magic.lua'

-- Add your custom rules
include 'local.rules'
EOF

# Create additional necessary files (placeholders)
touch /etc/snort/rules/local.rules
touch /etc/snort/snort_defaults.lua
touch /etc/snort/file_magic.lua


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


ip link set dev eth0 promisc on
if ethtool -k eth0 | grep -q 'generic-receive-offload: off'; then
	echo "generic-receive-offload is off"
else
	ethtool -K eth0 gro off
fi

systemctl daemon-reload
systemctl start snort3-nic.service
systemctl enable snort3-nic.service

# create a new directory to store the rules file
mkdir /usr/local/etc/rules
cd /usr/local/etc/rules
wget -qo- https://www.snort.org/downloads/community/snort3-community-rules.tar.gz
tar -xzf snort3-community-rules.tar.gz

echo "open the configuration file and add the Home network and include the rulesfiles path to assign rules to your snort machine"



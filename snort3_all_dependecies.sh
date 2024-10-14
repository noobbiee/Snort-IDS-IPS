!/bin/bash

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

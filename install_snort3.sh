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




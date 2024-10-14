#! /bin/bash

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

# Create Systemd Service for Snort
echo "Creating systemd service for Snort..."
cat <<EOF > /etc/systemd/system/snort.service
[Unit]
Description=Snort NIDS Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/snort -c /etc/snort/snort.lua -i eth0 -A console -s 65535 -k none
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and Start Snort Service
echo "Enabling and starting Snort service..."
systemctl daemon-reload
systemctl enable snort.service
systemctl start snort.service

echo "Snort installation and configuration complete."
echo "Use 'systemctl status snort.service' to check the status of the Snort service."

# Perform a basic test to confirm Snort installation
echo "Performing a basic test to confirm Snort installation..."
snort -V

if [ $? -eq 0 ]; then
    echo "Snort installation confirmed successfully."
else
    echo "There was an issue confirming the Snort installation."
fi

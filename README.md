# Snort-IDS-IPS
The two script provided will help you to install and set up the snort

# Prerequisities
- You have a kali linux in the your system and have root priviliges

# Features
- update and upgrades your system
- install all the necessary packages required
- install the luajit and daq for snort
- install the snort from the source
- sets and download the rules file from the snort websites
- configure the snort as ids or ips by refering to the configuration files presented

# Installation
- clone the repository using bash
  sudo git clone https://github.com/noobbiee/Snort-IDS-IPS/

# Run the script
navigate inside the Snort-IDS-IPS
Then
make the script executable by using
sudo chmod 777 install_snort3.sh

run the script as root or give root access to the script
and wait for it to install 
the rules fils are installed in the /usr/local/etc/rules

# Configure as ids
set up your ip address in HOME_NET, then configure EXTERNAL_NET = !$HOME_NET
include the rules files in the ips dictionary
rules =[[
    include /usr/local/etc/rules/snort3-community-rules/snort3-community.rules
   
    ]]
add the following line and run the snort as Intrusion Detection System

# Configure as ips
In order for the snort to work as the ips it needs to drop or reject the network traffic that matches the signatures in our rules file.
change the ips dictionary as below
ips = {
    -- use this to enable decoder and inspector alerts
    mode = inline,
    enable_builtin_rules = true,
    

    -- use include for rules files; be sure to set your path
    -- note that rules files can include other rules files
    -- (see also related path vars at the top of snort_defaults.lua)

    variables = default_variables,
    action_override = 'reject',
    rules =[[
    include /usr/local/etc/rules/snort3-community-rules/snort3-community.rules
    
    ]]
}

-The data acquisition modules also needs to be changed into from pcap, so we will be using afpacket to stop packets in realtime.
-add this below the ips dictionary
daq = {
	module_dirs = {
		'/usr/local/lib/',
	},
	modules = {
		{
			name = 'afpacket',
			mode = 'inline',
			variables = {
				'fanout_type=hash'
			}
		}
	}
}
make changes to alert_fast, alert_full to gnerate alerts and log it.
alert_fast = { file = true }
alert_full = { file = true }

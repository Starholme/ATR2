#!/bin/bash

echo Setting file permissions
#sudo chmod 777 cacheup.sh

echo Setting up network
sudo cp config.yaml /etc/netplan
sudo netplan generate
sudo netplan apply

echo Installing nmon
sudo apt-get install nmon

echo Enabling and configuring firewall rules
sudo ufw default deny incoming
sudo ufw default deny outgoing
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
sudo ufw allow from 172.16.1.0/24 to any port 8181
sudo ufw enable

echo Completed. Please run upandauto to update and restart the system.

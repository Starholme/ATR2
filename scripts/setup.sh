#!/bin/bash

echo Setting file permissions
#sudo chmod 777 cacheup.sh

echo Setting up network
sudo cp config.yaml /etc/netplan
sudo netplan generate
sudo netplan apply

echo Configuring Prometheus
sudo cp prometheus.yml /var/snap/prometheus/current/prometheus.yml

echo Updating apt package list
sudo apt update

echo Installing nmon
sudo apt install -y nmon

echo Installing nginx
sudo apt install -y nginx
echo Installing certbot
sudo apt install -y certbot python3-certbot-nginx

echo Enabling and configuring firewall rules
sudo ufw default deny incoming
sudo ufw default deny outgoing
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
sudo ufw allow from 172.16.1.0/24 to any port 8181
sudo ufw allow from 172.16.1.0/24 to any port 9090
sudo ufw allow 31490:31500/udp
sudo ufw enable

echo Completed. Please run upandauto to update and restart the system.

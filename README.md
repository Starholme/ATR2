## Setup

### Install Ubuntu 20.04 LTS
  - During install, ensure you choose to install SSH, Prometheus
  - Edit the config.yaml to set up the correct IP addresses, or DHCP
  - After install, copy and run the scripts
  - `scp *.* username@someip:`
  - `scp .* username@someip:`
  - Reload bash
  - `exec bash`
  - Copy the other files to a setup folder
  - `mkdir setup`
  - `mv * setup/`
  - `cd setup`
  - Execute the setup script
  - `bash setup.sh`
  - The setup script should
    - setup the network based on config.yaml
	- setup prometheus based on prometheus.yml
    - Install nmon
    - Install nginx
  - Update and restart
  - `upandauto`

### Configure nginx
  - Create a folder for your domain
  - `sudo mkdir -p /var/www/atr/html`
  - `sudo chown -R $USER:$USER /var/www/atr/html`
  - `sudo cp nginx_atr /etc/nginx/sites-available/nginx_atr`
  - `sudo ln -s /etc/nginx/sites-available/nginx_atr /etc/nginx/sites-enabled/`

### Configure CertBot
  - `sudo certbot --nginx -d alltherockets.duckdns.org -d www.alltherockets.duckdns.org`
  - Add the auto renew to cron `crontab -e`
  - Add this line: `0 12 * * * /usr/bin/certbot renew --quiet`
  - Test the auto renew `sudo certbot renew --dry-run`

### Install nodejs, clusterio, and factorio
  - Choose a directory to be the Cluster Root.
  - `mkdir \atr`
  - `cd \atr`
  - `curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -`
  - `sudo apt-get install -y nodejs npm`
  - Check your node version, currently needs to be 14
  - `node -v`
  - `npm init -y`
  - `npm install @clusterio/master @clusterio/slave @clusterio/ctl`
  - `wget -O factorio.tar.gz https://www.factorio.com/get-download/latest/headless/linux64`
  - `tar -xf factorio.tar.gz`

### Configure master server
  - Navigate to Cluster Root
  - Set the local only HTTP port
  - `npx clusteriomaster config set master.http_port 8181`
  - Setup an admin account
    - This MUST be your valid factorio username!
  - `npx clusteriomaster bootstrap create-admin <username>`
  - `npx clusteriomaster bootstrap create-ctl-config <username>`

### Install plugins
  - Must be installed on the master and each remote slave
  - Navigate to Cluster Root
  - `npm install @clusterio/plugin-global_chat`
  - `npx clusteriomaster plugin add @clusterio/plugin-global_chat`
  - `npm install @clusterio/plugin-subspace_storage`
  - `npx clusteriomaster plugin add @clusterio/plugin-subspace_storage`
  - `npm install @clusterio/plugin-statistics_exporter`
  - `npx clusteriomaster plugin add @clusterio/plugin-statistics_exporter`
  - `npm install @hornwitser/server_select`
  - `npx clusteriomaster plugin add @hornwitser/server_select`

### Install mods
  - Download current mods
    - https://mods.factorio.com/mod/clusterio_lib
	- https://mods.factorio.com/mod/subspace_storage
  - Place in ClusterRoot\sharedMods folder

### Configure a local slave
  - Start the master server, see "Running: Start the master server" below
  - Navigate to Cluster Root
  - Create the configuration
  - `npx clusterioctl slave create-config --name local --generate-token`
  - Update the 'public_address' in config-slave.json to match your DNS name or IP address

### Configure a remote slave
TODO

## Running

### Start the master server
  - Navigate to the Cluster Root
  - `screen -R master`
  - `npx clusteriomaster run`
  - Log into the UI at http://127.0.0.1:8181/
  - The token can be found in `config-control.json`

### Start local slave
  - Navigate to the Cluster Root
  - `screen -R slave`
  - `npx clusterioslave run`
  - This slave should now be visible in the UI

### Create and Start an instance
  - Can be created and started via the UI as well
  - Instances are created, assigned to a slave, then started
  - One slave can run multiple instances
  - Navigate to the Cluster Root
  - `npx clusterioctl instance create "My Instance Name"`
  - `npx clusterioctl instance assign "My Instance Name" "Slave Name"`
  - Adjust configuration as required - suggest using UI
    - game_port, between 34190 and 34200
	- name = "[ATR] All The Rockets - World X"
	- description = "ATR is a cooperative game that is intended to provide some continuity across map resets. \nSERVER_TEXT \nMAP_INFO"
	- tags ["clusterio","ATR","COOP"]
	- username set to factorio username
	- token set to service token from player-data.json
  - Move the desired save file to the instance save folder
  - `npx clusterioctl instance start "My Instance Name"`

### Stop an Instance
  - Use the UI OR
  - `npx clusterioctl instance stop "My Instance Name"`

### Stop a slave (local or remote)
  - Use the UI

### Stop the master server
  - Navigate to the Cluster Root
  - `npx clusteriomaster stop`

### Use screen to keep running while detached
  - This is ideal when running over SSH, or if you don't want to leave terminals open
  - Start a new screen session with `screen -S somename`
  - Start your long running process, like the master server
  - CTRL-A CTRL-D to detach
  - Reattach to it with `screen -R` later
  - List screen sessions with `screen -list`

# Updates

## Factorio
  - Starting in the Cluster Root
  - Download the newest headless server
  - `wget -O factorio.tar.gz https://www.factorio.com/get-download/latest/headless/linux64`
  - Untar
  - `tar -xf factorio.tar.gz`
  - Stop and start each instance

## Clusterio
  - Stop the cluster
  - Starting in the Cluster Root
  - `npm update`
  - Start the cluster

## Ubuntu
  - The 'upandauto' alias does the following:
    - sudo apt-get update
	- sudo apt-get upgrade
	- sudo apt-get autoremove
    - sudo shutdown -r now
  - `upandauto'

# Removing a instance

## Extract metrics
 - Open up the clusterio metrics endpoint: https://127.0.0.1/clusterio/metrics
 - Copy the entire page
 - Paste into notepad++
 - Use find replace with regex .*^(?!.*yourInstanceIDhere).*$
 - Followed by ^\s* to remove empy lines
 - Should have only a list of items that reference your instance now
 - Copy all lines the reference your instance
 - Open up the site\archive.txt
 - Paste in the lines that reference your instance

## Stop instance
 - Stop the instance through clusterio

## Archive instance save
 - Navigate to atr/instances/instancename/saves
 - Copy the latest .zip to the archive folder
 - `cp ./somesave /var/www/atr/html/archive/worldname.zip`

## Update webpage
 - Adjust the webpage, moving the world to the dead section
 - Add a reason, and a save download link

# Adding a instance

## Edit scenario config
 - Turn off test mode
 - Add some map description

## Create world in single player
 - Create the world
 - Update subspace storage settings
 - Save the world

## Upload to server
 - Create a new instance
 - Upload the save from above

## Add instance to webpage
 - Duplicate a server card, updating the instance id and info

## Start instance
 - Start the instance in clusterio

## Test
 - Ensure you can log in


### Create and Start an instance
  - Can be created and started via the UI as well
  - Instances are created, assigned to a slave, then started
  - One slave can run multiple instances
  - Navigate to the Cluster Root
  - `npx clusterioctl instance create "My Instance Name"`
  - `npx clusterioctl instance assign "My Instance Name" "Slave Name"`
  - Adjust configuration as required - suggest using UI
    - game_port, between 34190 and 34200
	- name = "[ATR] All The Rockets - World X"
	- description = "ATR is a cooperative game that is intended to provide some continuity across map resets. \nSERVER_TEXT \nMAP_INFO"
	- tags ["clusterio","ATR","COOP"]
	- username set to factorio username
	- token set to service token from player-data.json
  - Move the desired save file to the instance save folder
  - `npx clusterioctl instance start "My Instance Name"`

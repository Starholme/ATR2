## Setup

### Install Ubuntu 20.04 LTS
  - During install, ensure you choose to install SSH
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
  - Update and restart
  - `upandauto`

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

### Configure a remote slave
TODO

## Running

### Start the master server
  - Navigate to the Cluster Root
  - `npx clusteriomaster run`
  - Log into the UI at http://127.0.0.1:8181/
  - The token can be found in `config-control.json`

### Start local slave
  - Navigate to the Cluster Root
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
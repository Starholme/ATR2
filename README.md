## Setup

### Install nodejs, clusterio, and factorio
  - Choose a directory to be the Cluster Root.
  - `mkdir \atr`
  - `cd \atr`
  - `sudo apt update`
  - `sudo apt install nodejs npm`
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

### Configure a local slave
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
  - `npx clusterioctl instance start "My Instance Name"`

 

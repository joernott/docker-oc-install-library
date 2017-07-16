# Common install functions for docker builds

This repository contains a set of shell functions to be used by various
docker build scripts.

## Usage:
```bash
wget -O /tmp/install/functions.sh https://raw.githubusercontent.com/joernott/docker-oc-install-library/master/install_functions.sh
source /tmp/install/functions.sh
```
## Function Overview:

### install_software
Wrapper around yum to install software

### install_java8
Fetches and installs oracle java 8

### get_gosu
Fetches and installs gosu

### create_user_and_group
Cretaes a user for running an application as unprivileged user

### cleanup
Clean up /tmp and remove unneeded packages

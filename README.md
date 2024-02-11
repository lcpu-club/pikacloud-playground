# PikaCloud Playground

This repo provides a playground for [PikaCloud](https://github.com/lcpu-club/pikacloud). Setting up a physical cluster can be time-consuming and expensive, so we use Vagrant to create a virtual cluster. This allows us to develop PikaCloud without needing to invest in hardware.

## Overview

### Virtual Cluster Layout

The virtual cluster consists of 5 VMs:

- `mgt`: The management node. It runs the management software, such as storage management, network management
- `server`: The server node. It runs the supporting services, such as Ceph storage cluster, ETCd cluster and PostgreSQL cluster.
- `client`: The client node. It runs the compute services, such as the VM Engine and the Container engine.

Note that the physical cluster layout is different from the virtual cluster layout. This layout is designed for the development and testing purpose.

## Install prerequisites

Install [Vagrant](http://www.vagrantup.com/downloads.html) and [VirtualBox](https://www.virtualbox.org/).

The VMs will be install in `~/VirtualBox VMs` by default. If you want to change the location, you can run the following command:

```bash
VBoxManage setproperty machinefolder /path/to/your/vm/folder
```

We assume you use `virtualbox` as the provider. If you use `libvirt` or other providers, you need to change the `Vagrantfile` to use `libvirt` as the provider and modify the provider-specific settings, such as the network configuration and the amount of memory. The platform is tested on Linux with newer versions of Vagrant and VirtualBox. No Windows support is planned.

We'll also need some plugins for Vagrant. Install the following:

```bash
vagrant plugin install vagrant-cachier
vagrant plugin install vagrant-hostmanager
vagrant plugin install vagrant-scp
```


## Add your Vagrant key to the SSH agent

Since the admin machine will need the Vagrant SSH key to log into the server machines, we need to add it to our local SSH agent:

On Mac:
```console
$ ssh-add -K ~/.vagrant.d/insecure_private_key
```

On \*nix:
```console
$ ssh-add -k ~/.vagrant.d/insecure_private_key
```

## Start the VMs

Run the following command, if no error occurs, the VMs will be started. It will take a few minutes to download the base box and start the VMs.

```bash
bash pre-install.sh # Only run once!
vagrant up
```


## Deploy Ceph cluster

The cluster will be automatically deployed in the provisioning process. You can check the status of the cluster by running the following command:

```bash
ceph -s
```

If you are interested in the details of deployment, you can check the `deploy-ceph-*.sh` script.

## Deploy PostgreSQL cluster

TBD. Now only a single PostgreSQL instance is deployed on `mgt` node.

## Deploy ETCD cluster

TBD. Now only a single ETCD instance is deployed on `mgt` node.

## Deploy PikaCloud

TBD. Now only the basic environment is deployed.

## Post-installation

The necessary information such as Database password is listed in the `cluster-shared/installation-report.txt` file. 

You must run 

```
bash post-install.sh
```

to complete the installation.

## Next Steps

- [ ] Deploy PostgreSQL cluster

## Troubleshoot

### Vagrant-related issues

- `mkdir -p /tmp/vagrant-cache/yum` failed: This is a known issue with the `vagrant-cachier` plugin. It can be safely ignored. Just run `vagrant halt` and `vagrant up` to continue.
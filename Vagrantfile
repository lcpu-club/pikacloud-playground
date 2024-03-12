# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/rocky9"
  config.ssh.forward_agent = true
  config.ssh.insert_key = false
  config.hostmanager.enabled = true
  config.cache.scope = :box
  config.vm.synced_folder "cluster-shared", "/vagrant", automount: true
  config.vm.define "mgt" do |admin|
    admin.vm.provider "virtualbox" do |v|
      v.memory = "4096"
      v.cpus = 4
      v.linked_clone = true
      v.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    end

    admin.vm.hostname = "mgt"
    admin.vm.network :private_network, ip: "192.168.56.10"
    admin.vm.provision "shell", path: "prepare-env.sh", privileged: true
    admin.vm.provision "shell", path: "deploy-ceph-mgt.sh", privileged: true
    admin.vm.provision "shell", path: "deploy-etcd-mgt.sh", privileged: true
    admin.vm.provision "shell", path: "deploy-psql-mgt.sh", privileged: true
    admin.vm.disk :disk, size: "40GB", name: "mgt"

  end

  num_of_server = 3
  (1..(num_of_server)).each do |node|

    node_name = "server-#{node}"

    config.vm.define node_name do |server|
      server.vm.provider :virtualbox do |v|
        v.memory = "2048"
        v.cpus = 2
        v.linked_clone = true
        v.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
      end

      server.vm.hostname = node_name
      server.vm.network "private_network", ip: "192.168.56.#{node+10}"
      server.vm.disk :disk, size: "20GB", name: "ceph_storage"

      server.vm.provision "shell", path: "prepare-env.sh", privileged: true
      server.vm.provision "shell", path: "deploy-ceph-server.sh", privileged: true
      server.vm.provision "shell", path: "deploy-etcd-server.sh", privileged: true
      server.vm.provision "shell", path: "deploy-psql-server.sh", privileged: true
    end
  end

  num_of_client = 2
  (1..(num_of_client)).each do |node|
    
    node_name = "client-#{node}"

    config.vm.define node_name do |client|
      client.vm.provider "virtualbox" do |v|
        v.memory = "2048"
        v.cpus = 2
        v.linked_clone = true
        v.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
      end
      client.vm.hostname = node_name
      client.vm.network "private_network", ip: "192.168.56.#{node+20}"
      client.vm.provision "shell", path: "prepare-env.sh", privileged: true
      client.vm.provision "shell", path: "deploy-ceph-client.sh", privileged: true
    end
  end
end

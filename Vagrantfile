#! /usr/bin/env ruby

DEFAULT_BOX = "centos/7"
K8S_CTRL_PREFIX = "k8s-ctrl"
K8S_NODE_PREFIX = "k8s-node"
K8S_CTRL_NUM = 1
K8S_NODE_NUM = 2

def provision_k8s_machine(node, node_name, ip)
  node.vm.hostname = node_name
  node.vm.network "private_network", ip: ip
  node.vm.provider "virtualbox" do |vb|
    vb.name = node_name
  end

  node.vm.provision "docker", type: "shell" do |s|
    s.path = "scripts/centos7/docker.sh"
  end

  node.vm.provision "kubernetes", type: "shell" do |s|
    s.path = "scripts/centos7/kubernetes.sh"
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = DEFAULT_BOX
  config.vm.box_check_update = false

  config.hostmanager.enabled = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true
  
  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = "2048"
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.provision "bootstrap", type: "shell" do |s|
    s.path = "scripts/centos7/bootstrap.sh"
  end

  config.vm.provision :reload

  (1..K8S_NODE_NUM).reverse_each do |machine_id|
    node_name = "#{K8S_NODE_PREFIX}-#{machine_id}"
    ip = "192.168.8.#{100+machine_id}"
    config.vm.define node_name do |node|
      provision_k8s_machine node, node_name, ip
    end
  end

  (1..K8S_CTRL_NUM).reverse_each do |machine_id|
    node_name = "#{K8S_CTRL_PREFIX}-#{machine_id}"
    ip = "192.168.8.#{10+machine_id}"
    if machine_id == 1
      config.vm.define node_name, primary: true do |node|
        node.vm.network "forwarded_port", guest: 6443, host: 6443, auto_correct: true
        node.vm.network "forwarded_port", guest: 8001, host: 8001, auto_correct: true
        provision_k8s_machine node, node_name, ip
        node.vm.provision "init-kubernetes-cluster", type: "shell" do |s|
          s.path = "scripts/centos7/init-kubernetes-cluster.sh"
        end
        node.vm.provision "remove-kubernetes-cluster", type: "shell", run: "never" do |s|
          s.path = "scripts/centos7/remove-kubernetes-cluster.sh"
        end
        node.vm.provision "install-kubernetes-dashboard", type: "shell", run: "never" do |s|
          s.path = "scripts/centos7/install-kubernetes-dashboard.sh"
        end
        node.vm.provision "install-helm", type: "shell", run: "never" do |s|
          s.path = "scripts/centos7/install-helm.sh"
        end
      end
    else
      config.vm.define node_name do |node|
        provision_k8s_machine node, node_name, ip
      end
    end
  end
end

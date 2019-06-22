#! /bin/bash

set -uexo pipefail

NODES=$(cat /etc/hosts | grep k8s-node | cut -f 2)
for node in ${NODES[@]} ; do
  sudo -uvagrant kubectl drain $node --delete-local-data --force --ignore-daemonsets
  sudo -uvagrant kubectl delete node $node
done

kubeadm reset -f

rm -rf /var/lib/etcd/*

iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

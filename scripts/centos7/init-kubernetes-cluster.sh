#! /bin/bash

set -uexo pipefail

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

MASTER_IP=$(hostname -i | cut -d' ' -f 2)
POD_CIDR=10.244.0.0/16

kubeadm init --kubernetes-version=v1.15.0 \
  --apiserver-advertise-address $MASTER_IP \
  --pod-network-cidr=$POD_CIDR \
  --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers

mkdir -p /home/vagrant/.kube
cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# https://docs.projectcalico.org/v3.7/getting-started/kubernetes/installation/calico
curl https://docs.projectcalico.org/v3.7/manifests/calico.yaml -O
sed -i -e "s?192.168.0.0/16?$POD_CIDR?g" calico.yaml
sudo -uvagrant kubectl apply -f calico.yaml
rm -rf calico.yaml
sudo -uvagrant kubectl taint nodes --all node-role.kubernetes.io/master-

TOKEN=$(kubeadm token list | tail -n 1 | cut -d' ' -f 1)
SHA256_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
JUMP_CMD="kubeadm join $MASTER_IP:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$SHA256_HASH"

NODES=$(cat /etc/hosts | grep k8s-node | cut -f 1)
for node in ${NODES[@]} ; do
  sudo -uvagrant ssh -o StrictHostKeyChecking=no $node sudo $JUMP_CMD
done

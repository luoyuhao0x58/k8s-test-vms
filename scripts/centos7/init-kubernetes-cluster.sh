#! /bin/bash

set -uexo pipefail

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

MASTER_IP=$(hostname -i | cut -d' ' -f 2)
POD_CIDR=10.244.0.0/16

# https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2
cat > config.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $MASTER_IP
nodeRegistration:
  name: $(hostname)
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiVersion: kubeadm.k8s.io/v1beta2
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: v1.15.0
networking:
  podSubnet: "$POD_CIDR"
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
featureGates:
  SupportIPVSProxyMode: true
mode: ipvs
EOF
kubeadm init --config config.yaml && rm -f config.yaml

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

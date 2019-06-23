#! /bin/bash

set -uexo pipefail

curl -O https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
sed -i 's/k8s.gcr.io/registry.cn-hangzhou.aliyuncs.com\/google_containers/g' kubernetes-dashboard.yaml
sudo -uvagrant kubectl apply -f kubernetes-dashboard.yaml
rm -f kubernetes-dashboard.yaml

# https://github.com/kubernetes/dashboard/wiki/Access-control#admin-privileges
cat > dashboard-admin.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
EOF
sudo -uvagrant kubectl create -f dashboard-admin.yaml

echo "Note: kubectl proxy --address='0.0.0.0' --accept-hosts='^*$'"

echo "===========================TOKEN============================"
echo `sudo -uvagrant kubectl -n kube-system describe secret $(sudo -uvagrant kubectl -n kube-system get secret | grep kubernetes-dashboard | awk '{print $1}') | grep token: | cut -d':' -f 2`
echo "============================================================"

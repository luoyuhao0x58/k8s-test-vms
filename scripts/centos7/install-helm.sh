#! /bin/bash

set -uexo pipefail

# https://helm.sh/docs/using_helm/#from-snap-linux
snap install helm --classic

# https://helm.sh/docs/using_helm/#initialize-helm-and-install-tiller
sudo -iuvagrant helm init --history-max 200

# https://github.com/helm/helm/issues/3130#issuecomment-372931407
sudo -iuvagrant kubectl --namespace kube-system create serviceaccount tiller
sudo -iuvagrant kubectl create clusterrolebinding tiller-cluster-rule \
  --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
sudo -iuvagrant kubectl --namespace kube-system patch deploy tiller-deploy \
  -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

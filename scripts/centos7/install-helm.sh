#! /bin/bash

set -uexo pipefail

# https://helm.sh/docs/using_helm/#from-snap-linux
snap install helm --classic

# https://helm.sh/docs/using_helm/#initialize-helm-and-install-tiller
sudo -iuvagrant helm init --history-max 200

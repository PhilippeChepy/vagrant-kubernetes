WORKER_NODES = 2
IMAGE = "./packer/output-kubernetes/package.box"

CONTROL_PLANE_ADDRESS="10.10.0.10"

# KUBEADM_TOKEN contains a default token, used by worker nodes to join the control plane.
# The default value provided here is not suitable for production as the content of this 
# variable must be kept secure.
KUBEADM_TOKEN = "aaaaaa.aaaaaaaaaaaaaaaa"

# `$install_control_plane_script` is an helper script that install a kubeadm configuration
# and calls kubeadm init. This script take the KUBEADM_TOKEN as argument.
$install_control_plane_script = <<-'SCRIPT'
#!/bin/bash

set -e
set -o pipefail

if [ "$#" -lt 1 ]; then
    echo "usage: install-control-plane.sh <kubeadm-token>"
    exit 2
fi

KUBEADM_TOKEN=$1

cat <<EOF | sudo tee /etc/kubernetes/kubeadmcfg.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- token: "${KUBEADM_TOKEN}"
  description: "default kubeadm bootstrap token"
  ttl: "0"
localAPIEndpoint:
  advertiseAddress: 10.10.0.10
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

# control-plane initialization
sudo kubeadm reset --force
sudo kubeadm init --config /etc/kubernetes/kubeadmcfg.yaml \
    --skip-phases=addon/kube-proxy

# setup kubectl for root user
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config

sudo helm repo add cilium https://helm.cilium.io/

sudo helm install cilium cilium/cilium --version 1.9.4 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=10.10.0.10 \
    --set k8sServicePort=6443
SCRIPT

# `$install_worker_script` is an helper script that joins the control-plane from a worker node.
# This script take the control plane IP address and KUBEADM_TOKEN as argument.
$install_worker_script = <<-'SCRIPT'
#!/bin/bash

set -e
set -o pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: install-worker.sh <control-plane-address> <kubeadm-token>"
    exit 2
fi

CONTROL_PLANE_ADDRESS=$1
KUBEADM_TOKEN=$2

# worker node initialization
sudo kubeadm reset --force
sudo kubeadm join --token "${KUBEADM_TOKEN}" \
    --discovery-token-unsafe-skip-ca-verification \
    ${CONTROL_PLANE_ADDRESS}:6443
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.define "control-plane" do |server|
    server.vm.box = IMAGE
    server.vm.hostname = "control-plane"

    server.vm.provider "virtualbox" do |node|
      node.gui = false
      node.memory = "2048"
    end
    server.vm.network :private_network, ip: CONTROL_PLANE_ADDRESS
    
    server.vm.provision "shell" do |s|
      s.inline = $install_control_plane_script
      s.args   = [KUBEADM_TOKEN]
    end
  end

  (1..WORKER_NODES).each do |server_index|
    config.vm.define "worker-#{server_index}" do |node|
      node.vm.box = IMAGE
      node.vm.hostname = "worker-#{server_index}"
      node.vm.network :private_network, ip: "10.10.0.#{server_index + 10}"

      node.vm.provider "virtualbox" do |node|
        node.gui = false
        node.memory = "2048"
      end

      node.vm.provision "shell" do |s|
        s.inline = $install_worker_script
        s.args   = [CONTROL_PLANE_ADDRESS, KUBEADM_TOKEN]
      end
    end
  end
end
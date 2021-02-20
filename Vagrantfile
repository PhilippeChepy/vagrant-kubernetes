WORKER_NODES = 2
KUBE_IMAGE = "./packer/output-kubernetes/package.box"
INFLUX_IMAGE = "ubuntu/focal64"

# KUBEADM_TOKEN contains a default token, used by worker nodes to join the control plane.
# The default value provided here is not suitable for production as the content of this 
# variable must be kept secure.
KUBEADM_TOKEN = "aaaaaa.aaaaaaaaaaaaaaaa"

CONTROL_PLANE_PRIVATE_ADDRESS = "10.80.0.10"
MONITORING_PRIVATE_ADDRESS = "10.80.0.10"

# `$install_control_plane_script` is an helper script that install a kubeadm configuration
# and calls kubeadm init. This script take the KUBEADM_TOKEN as argument.
$install_control_plane_script = <<-'SCRIPT'
#!/bin/bash

set -e
set -o pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: install-control-plane.sh <kubeadm-token> <api-node-ip-address>"
    exit 2
fi

KUBEADM_TOKEN=$1
CONTROL_PLANE_PRIVATE_ADDRESS=$2

# control-plane initialization
sudo kubeadm reset --force
sudo kubeadm init \
    --apiserver-advertise-address $CONTROL_PLANE_PRIVATE_ADDRESS \
    --pod-network-cidr 10.112.0.0/12 \
    --service-cidr 10.96.0.0/12 \
    --token "${KUBEADM_TOKEN}" \
    --token-ttl 0 \
    --skip-phases=addon/kube-proxy

    

# setup kubectl for root user
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config

sudo helm repo add cilium https://helm.cilium.io/
sudo helm repo add fluent https://fluent.github.io/helm-charts

sudo helm install cilium cilium/cilium --version 1.9.4 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=$CONTROL_PLANE_PRIVATE_ADDRESS \
    --set k8sServicePort=6443 \
    --set ipam.operator.clusterPoolIPv4PodCIDR="10.112.0.0/12" \
    --set ipam.operator.clusterPoolIPv4MaskSize=24

# helm upgrade -i -n kube-platform -f fluent-bit/values.yaml fluent-bit fluent/fluent-bit
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

CONTROL_PLANE_PRIVATE_ADDRESS=$1
KUBEADM_TOKEN=$2

# worker node initialization
sudo kubeadm reset --force
sudo kubeadm join --token "${KUBEADM_TOKEN}" \
    --discovery-token-unsafe-skip-ca-verification \
    ${CONTROL_PLANE_PRIVATE_ADDRESS}:6443
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.define "control-plane" do |server|
    server.vm.box = KUBE_IMAGE
    server.vm.hostname = "control-plane"
    server.vm.network :private_network, ip: CONTROL_PLANE_PRIVATE_ADDRESS

    server.vm.provider "virtualbox" do |node|
      node.check_guest_additions = false
      node.memory = "2048"
      node.cpus = 2
    end
    
    server.vm.provision "shell" do |s|
      s.inline = $install_control_plane_script
      s.args   = [KUBEADM_TOKEN, CONTROL_PLANE_PRIVATE_ADDRESS]
    end
  end

  (1..WORKER_NODES).each do |server_index|
    config.vm.define "worker-#{server_index}" do |node|
      node.vm.box = KUBE_IMAGE
      node.vm.hostname = "worker-#{server_index}"
      node.vm.network :private_network, ip: "10.80.0.#{server_index + 10}"

      node.vm.provider "virtualbox" do |node|
        node.check_guest_additions = false
        node.memory = "2048"
        node.cpus = 2
      end

      node.vm.provision "shell" do |s|
        s.inline = $install_worker_script
        s.args   = [CONTROL_PLANE_PRIVATE_ADDRESS, KUBEADM_TOKEN]
      end
    end
  end
end
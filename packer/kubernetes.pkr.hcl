source "vagrant" "kubernetes" {
    box_name = "kubernetes"
    communicator = "ssh"
    source_path = "ubuntu/focal64"
    provider = "virtualbox"
    # add_force = true
    skip_add = true
}

build {
    sources = ["source.vagrant.kubernetes"]

    provisioner "file" {
        source = "kubernetes/etc/default/kubelet"
        destination = "/tmp/etc_default_kubelet"
    }

    provisioner "file" {
        source = "kubernetes/etc/modprobe.d/kubernetes-blacklist.conf"
        destination = "/tmp/etc_modprobe.d_kubernetes-blacklist.conf"
    }

    provisioner "file" {
        source = "kubernetes/etc/modules-load.d/cri-o.conf"
        destination = "/tmp/etc_modules-load.d_cri-o.conf"
    }

    provisioner "file" {
        source = "kubernetes/etc/networkd-dispatcher/routable.d/50-ifup-hooks"
        destination = "/tmp/etc_networkd-dispatcher_routable.d_50-ifup-hooks"
    }

    provisioner "file" {
        source = "kubernetes/etc/sysctl.d/99-kubernetes-cri.conf"
        destination = "/tmp/etc_sysctl.d_99-kubernetes-cri.conf"
    }

    # update system and install required components for Kubernetes
    provisioner "shell" {
        environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
        inline = [
            # fix most warnings from apt during image preparation
            "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",

            # run unattended upgrade and wait for it completion
            "sudo systemd-run --property='After=apt-daily.service apt-daily-upgrade.service' --wait /bin/true",

            # update system
            "sudo apt-get update",
            "sudo apt-get upgrade -y",
            "sudo apt-get install -y dialog apt-utils curl gnupg2 software-properties-common apt-transport-https ca-certificates",

            # Network configuration
            "sudo mv /tmp/etc_networkd-dispatcher_routable.d_50-ifup-hooks /etc/networkd-dispatcher/routable.d/50-ifup-hooks",
            "sudo chown root:root /etc/networkd-dispatcher/routable.d/50-ifup-hooks",
            "sudo chmod 0700 /etc/networkd-dispatcher/routable.d/50-ifup-hooks",

            # custom Kubernetes CRI & network configuration
            "sudo mv /tmp/etc_sysctl.d_99-kubernetes-cri.conf /etc/sysctl.d/99-kubernetes-cri.conf",
            "sudo mv /tmp/etc_modules-load.d_cri-o.conf /etc/modules-load.d/cri-o.conf",
            "sudo mv /tmp/etc_default_kubelet /etc/default/cri-o.conf",
            "sudo mv /tmp/etc_modprobe.d_kubernetes-blacklist.conf /etc/modprobe.d/kubernetes-blacklist.conf",

            # install CRI-O (as a replacement for Docker)
            "curl -s https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key | sudo apt-key add -",
            "curl -s https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.20/xUbuntu_20.04/Release.key | sudo apt-key add -",
            "sudo apt-add-repository \"deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04 /\"",
            "sudo apt-add-repository \"deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.20/xUbuntu_20.04/ /\"",

            "sudo apt-get update",
            "sudo apt-get install -y cri-o cri-o-runc cri-tools cri-o-runc runc",
            
            "sudo systemctl daemon-reload",
            "sudo systemctl start crio",
            "sudo systemctl enable crio",

            # install Kubernetes and Kubeadm components
            "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
            "sudo apt-add-repository \"deb https://apt.kubernetes.io/ kubernetes-xenial main\"",

            "sudo apt-get update",
            "sudo apt-get install -y kubectl=1.20.2-00 kubeadm=1.20.2-00 kubelet=1.20.2-00",

            # preload Kubernetes container images
            "sudo kubeadm config images pull",

            # install helm3
            "wget -O /tmp/helm.tar.gz https://get.helm.sh/helm-v3.5.1-linux-amd64.tar.gz",
            "tar -xOvf /tmp/helm.tar.gz linux-amd64/helm > /tmp/helm",
            "sudo install /tmp/helm /usr/local/bin/helm",

            # removed because of conflicts with (later) calico installation
            "sudo rm -f /etc/cni/net.d/*"
        ]
    }
}
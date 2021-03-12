# TL;DR

The goal of this repository is to set up a Kubernetes (1.20) cluster in vagrant.
You need to have `packer`, `virtualbox` and `vagrant` installed on your workstation.

Start:

```bash
make start
```

Cleanup:

```bash
make clean
```

# Forward local ports to cluster Ingress Controller

Traefik is set up as default Ingress Controller.
It is possible to forward all queries from the host ports 80 and 443 to cluster's Ingress Controller, running the `extra/local-lb.sh` script.

In order for this script to work, you need to have docker installed on your host, as it creates a `vagrant-kubernetes-haproxy` container.

# Components

- Kubernetes 1.20
- containerd as container runtime (CRI plugin)
- Cilium as CNI

- Traefik as Ingress Controller

# Networking

- VMs are in a shared network in the `10.80.0.0/16` subnet
- Kubernetes Services are in the `10.96.0.0/12` subnet
- Kubernetes Pods are in the `10.112.0.0/12` subnet

# References

* Kubernetes
  * [Website](https://kubernetes.io)
  * [Documentation](https://kubernetes.io/docs/home/)
* CRI-O
  * [Website](https://cri-o.io)
* Cilium
  * [Website](https://cilium.io)
* Packer
  * [Website](https://www.packer.io)
  * [Documentation](https://www.packer.io/docs)
  * [Creating Custom Templates Using Packer](https://www.exoscale.com/syslog/creating-custom-templates-using-packer/)
* Vagrant
  * [Website](https://www.vagrantup.com)
  * [Documentation](https://www.vagrantup.com/docs)

# Author

Philippe Chepy

* Github: [@PhilippeChepy](https://github.com/PhilippeChepy)
* LinkedIn: [@philippe-chepy](https://www.linkedin.com/in/philippe-chepy/)
* Website [EasyAdmin](https://easyadmin.tech)

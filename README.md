# TL;DR

The goal of this repository is to set up a Kubernetes cluster in vagrant.
You need to have `packer`, `virtualbox` and `vagrant` installed on your workstation.

Start:

```bash
make start
```

Cleanup:

```bash
make clean
```

# Components

- Kubernetes 1.20
- containerd as container runtime (CRI plugin)
- Cilium as CNI

# Networking

- VMs are in a shared network in the `10.80.0.0/16` subnet
- Kubernetes Services are in the `10.96.0.0/12` subnet
- Kubernetes Pods are in the `10.112.0.0/12` subnet

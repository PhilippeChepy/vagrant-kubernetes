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
- CRI-O as container runtime (CRI)
- Cilium as CNI
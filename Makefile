# Build settings
.PHONY: start
start: packer.build vagrant.up

.PHONY: clean
clean: vagrant.destroy vagrant.clean
	rm -rf packer/output-kubernetes

.PHONY: packer.build
packer.build:
	cd ./packer && (packer build kubernetes.pkr.hcl || true)

.PHONY: vagrant.up
vagrant.up:
	vagrant up

.PHONY: vagrant.ssh
vagrant.ssh:
	vagrant ssh control-plane

.PHONY: vagrant.destroy
vagrant.destroy:
	vagrant destroy --force

.PHONY: vagrant.clean
vagrant.clean:
	vagrant box remove ./packer/output-kubernetes/package.box
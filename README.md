# Terraform Kubernetes Deployment
This repository contains bash scripts to deploy virtual machines and add them into rancher

To configure deployment:
- Edit `main.tfvars` to your needs
- Start `./terraform-install.sh`
- I recommend using kubespray to install k8s. My configuration is included in kubespray/inventory/cluster.<br>My kubespray configuration uses: flannel, metallb, dashboard
- To start kubespray: `cd kubespray` `ansible-playbook -i inventory/cluster/inventory.ini --user cmemb --become --become-user=root --private-key ~/.ssh/id_rsa cluster.yml`

P.S. Util scripts containing `virsh` calls `sudo` inside because installation uri is `qemu:///system` (Can be changed in libvirt conviguration in `main.tf`)
Networking is done via creating new network `kube` and IP distribution is done via `dhcp4` It can lead to problems with MetalLB.
If you want to use MetalLB with different ip range, than of `kube` subnet, you must do necessary routing by yourself. This repository doesn't cover it (yet)<br>
If you don't want to - just specify address range matching the one of subnet. You can find MetalLB configuration in `kubespray/inventory/cluster/group_vars/addons.yml` or you can change it later via `kubectl edit configmap -n metallb-system config`
P.S.S. MetalLB Readiness probe may be failing due to: strconv.Atoi: parsing "metrics": invalid syntax (but the pods are working eventually, haven't worked it out yet)

Everything here is a subject to change
Reasoning behind this repo is basically to store history of my attempts in creating personal cluster
(Many of which are forever erased)

You're free to use any of these! I hope these snippets of mine will help somebody)

Kubespray is licensed under Apache 2.0 License

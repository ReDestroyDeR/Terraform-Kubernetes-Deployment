variable "hostname"   { default = "kubenode" }
variable "domain"     { default = "kubenode.com" }
variable "m_memoryMB" { default = 1024*1 }
variable "m_cpu"      { default = 1 }
variable "w_memoryMB" { default = 1024*1 }
variable "w_cpu"      { default = 1 }
variable "masters"    { default = 0 }
variable "workers"    { default = 1 }
variable "base_gb"    { default = 10 }
variable "data_gb"    { default = 10 }

terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.11"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Cloud-init configuration

data "template_file" "user_data" {
  template = file("${path.module}/cloud-init.cfg")
  vars = {
    hostname = var.hostname
    fqdn = "${var.hostname}.${var.domain}"
  }
}

data "template_file" "network_data" {
  template = file("${path.module}/network-conf.cfg")
}

# Cloudinit inject volumes

resource "libvirt_cloudinit_disk" "commoninit" {
    name           = "commoninit.iso"
    user_data      = data.template_file.user_data.rendered
    network_config = data.template_file.network_data.rendered
}

# Ubuntu volume

resource "libvirt_volume" "os_image" {
    name   = "os_image"
    source = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

# VM Volumes
# Volume specified for Ubuntu install (2GiB) and Kubernetes overhead (3-4 GiB at least)
resource "libvirt_volume" "volume-master" {
    name           = "volume-master-${count.index}"
    pool           = "default"
    size           = var.base_gb * 1024 * 1024 * 1024 # bytes to GiB (2^3 -> 2^33)
    base_volume_id = libvirt_volume.os_image.id
    format         = "qcow2"
    count          = var.masters
}

# Volume specified for Ubuntu install (2GiB) and Kubernetes overhead (3-4 GiB at least)
resource "libvirt_volume" "volume-worker" {
    name           = "volume-worker-${count.index}"
    pool           = "default"
    size           = var.data_gb * 1024 * 1024 * 1024 # bytes to GiB (2^3 -> 2^33)
    base_volume_id = libvirt_volume.os_image.id
    format         = "qcow2"
    count          = var.workers
}

# Network configuration

resource "libvirt_network" "kube_network" {
  name      = "kube"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = ["200.0.5.0/24"]
  autostart = true

  dns {
    enabled    = true
    local_only = false # Forward to upstream if local doesn't respond
  }
}

# Domain configuration

resource "libvirt_domain" "kubemaster" {
    name   = "kube-master-${count.index}"
    memory = var.m_memoryMB
    vcpu   = var.m_cpu
    count  = var.masters

    qemu_agent = true
    cloudinit  = libvirt_cloudinit_disk.commoninit.id

    # IMPORTANT
    # Ubuntu can hang is a isa-serial is not present at boot time.
    # If you find your cpu 100% and never is available this is why
    console {
      type        = "pty"
      target_port = "0"
      target_type = "serial"
    }

    graphics {
      type        = "spice"
      listen_type = "address"
      autoport    = true
    }

    disk {
      volume_id = element(libvirt_volume.volume-master.*.id, count.index)
    }

    network_interface {
      network_id     = libvirt_network.kube_network.id
      hostname       = "master"
      wait_for_lease = true
    }
}

resource "libvirt_domain" "kubeworker" {
    name   = "kube-worker-${count.index}"
    memory = var.w_memoryMB
    vcpu   = var.w_cpu
    count  = var.workers

    qemu_agent = true
    cloudinit  = libvirt_cloudinit_disk.commoninit.id

    # IMPORTANT
    # Ubuntu can hang is a isa-serial is not present at boot time.
    # If you find your cpu 100% and never is available this is why
    console {
      type        = "pty"
      target_port = "0"
      target_type = "serial"
    }

    graphics {
      type        = "spice"
      listen_type = "address"
      autoport    = true
    }

    disk {
      volume_id = element(libvirt_volume.volume-worker.*.id, count.index)
    }

    network_interface {
      network_id     = libvirt_network.kube_network.id
      hostname       = "worker"
      wait_for_lease = true
    }
}

output "master_ips" {
  value = libvirt_domain.kubemaster.*.network_interface.0.addresses
}

output "worker_ips" {
  value = libvirt_domain.kubeworker.*.network_interface.0.addresses
}

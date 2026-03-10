packer {
  required_plugins {
    name = {
      version = "~> 1"
      source = "github.com/hashicorp/proxmox"
    }
  }
}

variable "username" {
  type    = string
}

variable "password" {
  type    = string
}

variable "node" {
  type    = string
}

variable "port" {
  type    = string
}

variable "vm_name" {
  type = string
  default = "ubuntu-24.04-template" 
}

variable template_description {
  type = string
  default = ""
}

variable insecure_skip_tls_verify {
  type = bool
  default = true
}

variable cpu_type {
  type = string
  default = "host"
}

variable cores {
  type = string
  default = "2"
}

variable os {
  type = string
  default = "l26"
}

variable memory {
  type = string
  default = "2048"
}

variable disk_size {
  type = string
  default = "16G"
}

variable disk_storage_pool {
  type = string
}

variable network_adapter_model {
  type = string
  default = "virtio"
}

variable network_adapter_bridge {
  type = string
  default = "vmbr0"
}

variable network_adapter_firewall {
  type = string
  default = "false"
}

variable iso_file {
  type = string
}

variable iso_checksum {
  type = string
}

variable ssh_username {
  type = string
}

variable ssh_private_key_file_path {
  type = string
}

variable ssh_timeout {
  type = string
  default = "15m"
}

source "proxmox-iso" "ubuntu-server" {
  proxmox_url = "https://${var.node}:${var.port}/api2/json"
  username = "${var.username}"
  password = "${var.password}"
  insecure_skip_tls_verify = ${var.insecure_skip_tls_verify}
  
  node = "${var.node}"
  vm_name = "${var.vm_name}" 
  template_description = "${var.template_description}"
  cpu_type = "${cpu_type}"
  cores = "${cores}"
  os = "${l26}"
  memory = "${memory}"
  qemu_agent = true
  scsi_controller = "virtio-scsi-pci"
  
  disks {
    disk_size = "${disk_size}"
    storage_pool = "${disk_storage_pool}"
  }

  network_adapters {
    model = "${network_adapter_model}"
    bridge = "${network_adapter_bridge}"
    firewall = "${network_adapter_firewall}"
  }

  boot_iso {
    type = "scsi"
    unmount = true
    iso_file = "${var.iso_file}" 
    iso_checksum = "${var.iso_checksum}"
  }
  
  cloud_init = true

  cloud_init_storage_pool = "${disk_storage_pool}"
  
  ssh_username = "${var.ssh_username}"
  ssh_private_key_file = "${var.ssh_private_key_file_path}"

  ssh_timeout = "${var.ssh_timeout}"

  # Boot Commands
  boot = "c"
  boot_wait = "10s"
  http_directory = "http"
  # http_bind_address = "" # Uncomment this to specify IP address you'd like to use. This IP address will have to be the machine you are running Packer from.
  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]

}

build {
  sources = ["source.proxmox-iso.ubuntu-server"]
  
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync"
    ]
  }

  provisioner "file" {
      source = "files/99-pve.cfg"
      destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
      inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
  }
}

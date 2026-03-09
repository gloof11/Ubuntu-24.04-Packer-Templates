packer {
  required_plugins {
    name = {
      version = "~> 1"
      source = "github.com/hashicorp/proxmox"
    }
  }
}

variable "password" {
  type    = string
}

variable "username" {
  type    = string
}

variable "node" {
  type    = string
}

variable "port" {
  type    = string
}

source "proxmox-iso" "ubuntu-server" {
  # Proxmox Connection Settings
  proxmox_url = "https://${var.node}:${var.port}/api2/json"
  username = "${var.username}"
  password = "${var.password}"
  insecure_skip_tls_verify = true
  
  # VM Settings
  node = "${var.node}"
  vm_name = "ubuntu-24.04-template" # Set your Template Name. Default: ubuntu-24.04-template
  template_description = "" # Set your Template Description
  cpu_type = "host"
  cores = "2" # Set the amount of cores you want the template to have. Default: 2
  os = "l26"
  memory = "2048" # Set the the amount of RAM you want the template to have. Default: 2GB
  qemu_agent = true
  scsi_controller = "virtio-scsi-pci"
  
  # Disk settings
  disks {
    disk_size = "16G" # Set the amount of disk space you want the template to have. Default: 16GB
    
    # Set this to the storage pool you are using.
    # This will vary if you are using ZFS, LVM etc
    # For example:
    # storage_pool = "local-zfs"
    storage_pool = ""
  }

  # Network Settings
  network_adapters {
    model = "virtio"
    bridge = "vmbr0"
    firewall = "false"
  }

  # VM OS Settings
  boot_iso {
    type = "scsi"
    unmount = true

    # The iso must be uploaded to the Proxmox Node
    # You must also have the checksum for the iso file
    # For example: 
    # iso_file = "local:iso/ubuntu-24.04.3-live-server-amd64.iso"
    # iso_checksum = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
    iso_file = "" 
    iso_checksum = ""
  }
  
  # Cloud-Init Settings
  cloud_init = true

  # Set this to the storage pool you are using.
  # This will vary if you are using ZFS, LVM etc
  # For example:
  # storage_pool = "local-zfs"
  cloud_init_storage_pool = ""
  
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

  # SSH Settings
  ssh_username = ""
  ssh_private_key_file = "" # Path to the key file that you would like to use

  ssh_timeout = "15m"
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

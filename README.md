# Ubuntu-24.04-Packer-Templates
Ubuntu 24.04 Packer Templates for Multiple Service Providers

## Proxmox Template

This section details the Packer configuration used to build an Ubuntu 24.04 LTS template on Proxmox VE.

### What this template does

*   **Automated Installation**: Uses Cloud-Init (autoinstall) to perform a hands-off installation of Ubuntu 24.04.
*   **Guest Agent**: Installs and enables the QEMU Guest Agent for better integration with Proxmox.
*   **Updates**: Applies the latest security updates and patches during the build process.
*   **Cleanup**: Removes temporary files, SSH keys, and machine-id to ensure a clean template ready for cloning.

### Configuration

Users must configure the following variables to match their specific Proxmox environment. It is recommended to create a `proxmox.auto.pkrvars.hcl` file to store these values (ensure this file is git-ignored if it contains secrets).

#### Connection Details
*   `username`: The username for authentication (e.g., `root@pam`).
*   `password`: The password for authentication.
*   `node`: The specific node in the cluster where the build will run.
*   `port`: The specific port for the node.
*   `insecure_skip_tls_verify`: Whether to verify your HTTPS connection. (Defaults: true)

#### VM Settings
*   `vm_name`: Name of the resulting template. (Default: ubuntu-24.04-template)
*   `template_description`: Name of the template description.
*   `cpu_type`: Name of the CPU type. (Default: host)
*   `cores`: Number of CPU cores. (Default: 2)
*   `os`: Type of OS support (Default: l26)
*   `memory`: Amount of RAM in MB.

#### Disk Configurations
*   `disk_size`: Size of the hard disk in G. (Default: 16G)
*   `disk_storage_pool`: Where the disk will be created (e.g., `local`, `local-zfs`). 

#### Network Configuration
*   `network_adapter_model`: The model of NIC the VM will use. (Default: virtio)
*   `network_adapter_bridge`: The bridge that the VM will use. (Default: vmbr0)
*   `network_adapter_firewall`: If the firewall will be enabled on the interface. (Default: false)

#### ISO Configuration
*   `iso_file`: The Proxmox storage pool where the ISO is stored (e.g., `"local:iso/ubuntu-24.04.3-live-server-amd64.iso"`).
*   `iso_checksum`: The SHA256 checksum of the ISO.

#### SSH & Cloud-Init
*   `ssh_username`: The user that will you will be authenticating with to the access the template VM. Ensure that this username lines up with the user in `files/user-data`. 
*   `ssh_private_key_file_path`: The path to the private key for authentication. Ensure that the corresponding public key is in `files/user-data`.
*   `ssh_timeout`: How long to wait for SSH to timeout. (Default: 15m) 

### Usage

Please ensure that your variables are set in a file, or are passed via the CLI

1.  **Initialize Packer** to download the required Proxmox builder plugin:
    ```bash
    packer init .
    ```

2.  **Validate** your configuration:
    ```bash
    packer validate .
    ```

3.  **Build** the template:
    ```bash
    packer build .
    ```

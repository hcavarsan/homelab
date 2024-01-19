resource "proxmox_virtual_environment_vm" "machines" {
  for_each = local.machines

  node_name = local.proxmox_node
  name = each.key
  description = "TalOS VM to deploy kubernetes"
  on_boot = true

  clone {
    datastore_id = local.proxmox_images_datastore
    node_name = local.proxmox_node
    vm_id = proxmox_virtual_environment_vm.talos.vm_id
  }

  cpu {
    cores = var.kubernetes.node_cpus
    type = "kvm64"
  }

  memory {
    dedicated = var.kubernetes.node_ram
  }

  disk {
    datastore_id = "nvme"
    interface = "scsi0"
    size = var.kubernetes.node_disk
    file_format = "raw"
  }

  initialization {
    datastore_id = local.proxmox_images_datastore
    interface = "ide2"

    ip_config {
      ipv4 {
        address = "${each.value}/${split("/", var.network.cidr)[1]}"
        gateway = var.network.gateway
      }
    }
  }

  depends_on = [null_resource.import_disk]

  lifecycle {
    ignore_changes = [started]
  }
}

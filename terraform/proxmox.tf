resource "null_resource" "import_disk" {
  connection {
    type     = "ssh"
    user     = local.ssh_username
    password = local.ssh_password
    host     = var.proxmox.host
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "cd /tmp",
      "wget -O talos.raw.xz https://github.com/siderolabs/talos/releases/download/v${var.talos.version}/nocloud-${var.talos.arch}.raw.xz",
      "unxz talos.raw.xz",
      "qm disk import ${proxmox_virtual_environment_vm.talos.vm_id} talos.raw ${local.proxmox_images_datastore} -format raw",
      "qm set ${proxmox_virtual_environment_vm.talos.vm_id} -scsi0 nvme:vm-${proxmox_virtual_environment_vm.talos.vm_id}-disk-0",
      "rm -f talos.raw*"
    ]
  }

  # Trigger re-provisioning whenever the disk image changes.
  triggers = {
    talos_version = var.talos.version
    talos_arch = var.talos.arch
    vm_id = proxmox_virtual_environment_vm.talos.vm_id
  }
}

resource "proxmox_virtual_environment_vm" "talos" {
  node_name = local.proxmox_node

  name = "talos-${var.kubernetes.cluster_name}"
  description = "TalOS VM to deploy kubernetes"

  memory {
    dedicated = "2048"
  }

  network_device {
    bridge = "vmbr0"
    firewall = false
  }

  cpu {
    cores = 2
    type = "kvm64"
  }

  kvm_arguments = "-cpu kvm64,+cx16,+lahf_lm,+popcnt,+sse3,+ssse3,+sse4.1,+sse4.2"

  operating_system {
    type = "l26"
  }

  vga {
    type = "virtio"
  }


  boot_order = ["scsi0", "net0"]
  started = false
  template = true
}

resource "null_resource" "proxmox-ccm-token" {
  provisioner "local-exec" {
    when = create
    command = <<-EOF
      TICKET_DATA=$(curl -s --insecure -X POST \
        https://${var.proxmox.host}:8006/api2/json/access/ticket \
        --data "username=${var.proxmox.username}&password=${var.proxmox.password}")
      TICKET=$(echo $TICKET_DATA | jq -r .data.ticket)
      CSRF=$(echo $TICKET_DATA | jq -r .data.CSRFPreventionToken)

      curl -s --insecure -X POST \
        https://${var.proxmox.host}:8006/api2/json/access/users/${var.proxmox.username}/token/k8s-${var.kubernetes.cluster_name}-ccm \
        --data "privsep=0" \
        -H "Cookie: PVEAuthCookie=$TICKET" \
        -H "CSRFPreventionToken: $CSRF" \
      | jq -r '. += {"host": "${var.proxmox.host}", "username": "${var.proxmox.username}", "password": "${var.proxmox.password}"}' > proxmox-token.json
    EOF
  }

  provisioner "local-exec" {
    when = destroy
    command = <<-EOF
      set +e

      HOST=$(cat proxmox-token.json | jq -r '.host')
      USERNAME=$(cat proxmox-token.json | jq -r '.username')
      PASSWORD=$(cat proxmox-token.json | jq -r '.password')
      TOKENID=$(cat proxmox-token.json | jq -r '.data["full-tokenid"]' | cut -d'!' -f2)

      TICKET_DATA=$(curl -s --insecure -X POST \
        https://$HOST:8006/api2/json/access/ticket \
        --data "username=$USERNAME&password=$PASSWORD")
      TICKET=$(echo $TICKET_DATA | jq -r .data.ticket)
      CSRF=$(echo $TICKET_DATA | jq -r .data.CSRFPreventionToken)

      curl -s --insecure -X DELETE \
        https://$HOST:8006/api2/json/access/users/$USERNAME/token/$TOKENID \
        -H "Cookie: PVEAuthCookie=$TICKET" \
        -H "CSRFPreventionToken: $CSRF"

      rm -f proxmox-token.json
      exit 0
    EOF
  }
}

data "external" "proxmox-ccm-token" {
  program = ["jq", "-cM", ".data | del(.info)", "proxmox-token.json"]

  depends_on = [null_resource.proxmox-ccm-token]
}

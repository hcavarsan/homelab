resource "talos_machine_secrets" "this" {
  talos_version = "v${var.talos.version}"
}

data "talos_machine_configuration" "this" {
  for_each = local.machines

  cluster_name     = var.kubernetes.cluster_name
  machine_type     = split("-", each.key)[1] == "control" ? "controlplane" : "worker"
  cluster_endpoint = "https://${cidrhost(var.network.cidr, var.network.control_plane_vip)}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  kubernetes_version = var.kubernetes.version
  talos_version = "v${var.talos.version}"

  config_patches = [
    templatefile(split("-", each.key)[1] == "control" ?
        "${path.module}/templates/controlplane.yaml.tpl" :
        "${path.module}/templates/worker.yaml.tpl" ,
      merge(
        { for k, v in var.network : "network_${k}" => v },
        { for k, v in var.kubernetes : "kubernetes_${k}" => v },
        { for k, v in var.talos : "talos_${k}" => v },
        {
          proxmox_node = local.proxmox_node
          hostname = each.key
          node_ip = each.value
          control_plane_vip = cidrhost(var.network.cidr, var.network.control_plane_vip)

          cloudflare_token = var.kubernetes.cloudflare_token

          identity         = "${file(var.kubernetes.private_key_file_path)}"
          identitypub      = "${file(var.kubernetes.public_key_file_path)}"
          knownhosts       = var.kubernetes.known_hosts
          manifests_cilium = data.helm_template.cilium.manifest
          manifests_promox_ccm = data.helm_template.proxmox-ccm.manifest
          manifests_csr_approver = data.helm_template.csr-approver.manifest
          manifests_external_dns = data.helm_template.external-dns.manifest
          manifests_csi_proxmox = data.helm_template.proxmox-ccm-csi-plugin.manifest
          # network
          pod_cidr = local.pod_cidr
          service_cidr = local.service_cidr
          new_subnet_bits = local.new_subnet_bits
          available_hosts_per_subnet = local.available_hosts_per_subnet
          test = true
        }
      )
    )
  ]
}

resource "talos_machine_configuration_apply" "this" {
  for_each = local.machines

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  node                        = each.value

  provisioner "local-exec" {
    when = destroy
    command = <<-EOF
      set -x
      talosctl \
        --talosconfig=talosconfig.yaml \
        -n ${self.node} \
        reset \
        --timeout 3m \
        $(echo ${each.key} \
        | grep -q control-0 \
          && echo "--graceful=false" \
          || echo "--graceful=true")
      exit 0
    EOF
    # The last control node needs to be graceful=false.
    # Assuming it will be control-0.
  }

  depends_on = [proxmox_virtual_environment_vm.machines]
}

resource "talos_machine_bootstrap" "this" {
  endpoint = cidrhost(var.network.cidr, var.network.control_first_ip)
  node = cidrhost(var.network.cidr, var.network.control_first_ip)
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_client_configuration" "this" {
  cluster_name = var.kubernetes.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration

  endpoints = concat(
    [
      cidrhost(var.network.cidr, var.network.control_plane_vip)
    ],[
      for key, value in local.machines :
        value if split("-", key)[1] == "control"
    ]
  )

  nodes = [
    for key, value in local.machines : value
  ]
}

resource "local_sensitive_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/talosconfig.yaml"

  provisioner "local-exec" {
    when = create
    command = <<-EOF
      talosctl \
        --talosconfig=talosconfig.yaml \
        --nodes ${cidrhost(var.network.cidr, var.network.control_first_ip)} \
        kubeconfig kubeconfig.yaml
    EOF
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm -f kubeconfig.yaml"
  }

  depends_on = [talos_machine_bootstrap.this]
}

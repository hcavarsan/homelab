terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
    proxmox = {
      source = "bpg/proxmox"
      version = "0.44.0"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.4.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.12.1"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.2"
    }
    local = {
      source = "hashicorp/local"
      version = "2.4.1"
    }
  }

  backend "s3" {
    bucket = "terraform"
    key    = "homeserver/terraform.tfstate"
    region = "us-east-1"

    skip_credentials_validation = true
    skip_region_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum = true
  }
}

locals {
  machines = merge({
    for machine in range(0, var.kubernetes.controls) :
      "${var.kubernetes.cluster_name}-control-${machine}" =>
        cidrhost(var.network.cidr,
          var.network.control_first_ip + machine)
  },{
    for machine in range(0, var.kubernetes.workers) :
      "${var.kubernetes.cluster_name}-worker-${machine}" =>
        cidrhost(var.network.cidr,
          var.network.worker_first_ip + machine)
  })
}

output "machines" {
  value = local.machines
}

locals {
  ssh_username = (var.proxmox.ssh_user != null ?
    var.proxmox.ssh_user : (
      length(regexall("(.*)@pam$", var.proxmox.username)) > 0 ?
        element(regexall("(.*)@pam$", var.proxmox.username), 0)[0] :
        var.proxmox.username
    )
  )
  ssh_password = var.proxmox.ssh_pass != null ? var.proxmox.ssh_pass : var.proxmox.password
}

provider "proxmox" {
  endpoint = "https://${var.proxmox.host}:8006"
  insecure = true

  username = var.proxmox.username
  password = var.proxmox.password
  api_token = var.proxmox.token_name != null ? "${var.proxmox.username}!${var.proxmox.token_name}=${var.proxmox.password}" : null

  ssh {
    username = local.ssh_username
    password = local.ssh_password
    agent = true
  }
}

data "proxmox_virtual_environment_nodes" "self" {}

locals {
  # picks the first node
  proxmox_node = data.proxmox_virtual_environment_nodes.self.names[0]
}

data "proxmox_virtual_environment_datastores" "self" {
  node_name = local.proxmox_node
}

locals {
  # picks the first iso datastore
  proxmox_iso_datastore = "nvme"
  # picks the first images datastore
  proxmox_images_datastore = "nvme"
}

locals {
  pod_cidr = cidrsubnet(
    var.kubernetes.cluster_cidr, 1, 0)
  service_cidr = cidrsubnet(
    var.kubernetes.cluster_cidr, 1, 1)

  pod_subnet_bits = tonumber(split("/", local.pod_cidr)[1])
  max_subnets = var.kubernetes.max_nodes

  required_subnet_bits = ceil(log(local.max_subnets, 2))
  new_subnet_bits = local.pod_subnet_bits + local.required_subnet_bits
  available_hosts_per_subnet = pow(2, (32 - local.new_subnet_bits)) - 2
  subnet_network_addresses = [
    for i in range(0, local.max_subnets) : cidrsubnet(local.pod_cidr, local.required_subnet_bits, i)
  ]
}

output "limits_txt" {
  value = trimspace(<<-EOF
    --- CLUSTER GENERAL INFO ---
    The address space is: ${var.kubernetes.cluster_cidr}
    Pods will have an address from: ${local.pod_cidr}
    Services will have an address from: ${local.service_cidr}

    It will be a maximum of ${local.max_subnets} nodes on the cluster.
    And each node could have a maximum of ${local.available_hosts_per_subnet} pods.
    ----------------------------
  EOF
  )
}

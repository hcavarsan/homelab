variable "proxmox" {
  type = object({
    host = string
    ssh_user = optional(string)
    ssh_pass = optional(string)
    username = string
    password = string
    token_name = optional(string)
  })
}

variable "talos" {
  type = object({
    version = string
    arch = string
  })

  default = {
    version = "1.6.1"
    arch = "amd64"
  }
}

variable "network" {
  type = object({
    cidr = string
    gateway = string
    dns_servers = set(string)
    domain = optional(string)
    control_plane_vip = number
    control_first_ip = number
    worker_first_ip = number
  })

  default = {
    cidr = "192.168.0.0/24"
    gateway = "192.168.0.1"
    dns_servers = ["8.8.8.8"]
    control_plane_vip = 100
    control_first_ip = 101
    worker_first_ip = 103
  }
}

variable "kubernetes" {
  type = object({
    version        = string
    cluster_name   = string
    cluster_domain = string
    cluster_cidr   = string
    max_nodes      = number
    controls       = number
    workers        = number
    node_cpus      = number
    node_ram       = number
    node_disk      = number
    private_key_file_path       = string
    public_key_file_path    = string
    known_hosts     = string
    cloudflare_token = string
  })

  default = {
    version        = "1.27.8"

    cluster_name   = "lab"
    cluster_domain = "cluster.local"
    cluster_cidr   = "192.168.192.0/22"

    max_nodes      = 4
    controls       = 1
    workers        = 0

    node_cpus      = 4
    node_ram       = 4096
    node_disk      = 32
    private_key_file_path = "value"
    public_key_file_path = "value"
    known_hosts = "value"
    cloudflare_token = "aaaa"
  }

  validation {
    condition     = length(var.kubernetes.version) > 0 && substr(var.kubernetes.version, 0, 1) != "-"
    error_message = "The version should be a non-empty string and should not start with a dash."
  }

  validation {
    condition     = length(var.kubernetes.cluster_name) > 0
    error_message = "The cluster name should be a non-empty string."
  }

  validation {
    condition     = length(var.kubernetes.cluster_domain) > 0
    error_message = "The cluster domain should be a non-empty string."
  }

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]+$", var.kubernetes.cluster_cidr)) && length(split("/", var.kubernetes.cluster_cidr)) == 2
    error_message = "The cluster CIDR should be a valid CIDR."
  }

  validation {
    condition     = var.kubernetes.max_nodes >= var.kubernetes.controls + var.kubernetes.workers
    error_message = "The total of controls and workers should not exceed max_nodes."
  }

  validation {
    condition     = floor(log(var.kubernetes.max_nodes, 2)) == log(var.kubernetes.max_nodes, 2)
    error_message = "max_nodes should be a power of 2 due to CIDR divisions."
  }

  validation {
    condition     = pow(2, (28 - tonumber(split("/", var.kubernetes.cluster_cidr)[1]))) >= var.kubernetes.max_nodes
    error_message = "The CIDR provided is too small for the number of nodes."
  }

  validation {
    condition     = var.kubernetes.controls > 0
    error_message = "At least one control node is required."
  }

  validation {
    condition     = var.kubernetes.workers >= 0
    error_message = "Workers should be zero or a positive integer."
  }

  validation {
    condition     = var.kubernetes.node_cpus > 0
    error_message = "Node CPUs should be a positive integer."
  }

  validation {
    condition     = var.kubernetes.node_ram >= 2048
    error_message = "Node RAM should be at least 2 GB."
  }

  validation {
    condition     = var.kubernetes.node_disk >= 16
    error_message = "Node disk should be at least 16 GB."
  }

  validation {
    condition     = cidrsubnet(var.kubernetes.cluster_cidr, 0, 0) != null
    error_message = "Invalid cluster CIDR provided."
  }

}

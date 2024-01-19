data "helm_template" "cilium" {
  name       = "cilium"
  namespace  = "cilium"
  repository = "https://helm.cilium.io"

  chart   = "cilium"
  version = "1.14.1"

  include_crds = true

  values = [<<-EOF
    ipam:
      mode: kubernetes

    tunnel: disabled
    bpf:
      masquerade: true
    endpointRoutes:
      enabled: true
    kubeProxyReplacement: true
    autoDirectNodeRoutes: true
    localRedirectPolicy: true
    l2announcements:
      enabled: true
      leaseDuration: 120s
      leaseRenewDeadline: 60s
      leaseRetryPeriod: 1s

    bgpControlPlane:
      enabled: true

    bgp:
      enabled: false
      announce:
        loadbalancerIP: true
        podCIDR: false

    loadBalancer:
      algorithm: random
      mode: dsr

    operator:
      replicas: 1
      rollOutPods: true
    rollOutCiliumPods: true

    routingMode: native
    ipv4NativeRoutingCIDR: "${var.kubernetes.cluster_cidr}"
    securityContext:
      privileged: true

    hubble:
      enabled: true
      metrics:
        enabled:
          - dns:query
          - drop
          - tcp
          - flow
          - port-distribution
          - icmp
          - http
      relay:
        enabled: true
        rollOutPods: true
      ui:
        enabled: true
        replicas: 1
        ingress:
          enabled: true
          className: traefik
          hosts:
            - hubble.cavarsa.app
    cgroup:
      autoMount:
        enabled: true
      hostRoot: /sys/fs/cgroup

    k8sServiceHost: localhost
    k8sServicePort: "7445"

    debug:
      enabled: true
      # verbose: flow,kvstore,envoy,datapath,policy
  EOF
  ]

  set {
    name = "securityContext.capabilities.ciliumAgent"
    value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  }

  set {
    name = "securityContext.capabilities.cleanCiliumState"
    value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  }
}

resource "null_resource" "proxmox-ccm" {
  provisioner "local-exec" {
    when = create
    command = <<-EOF
      git clone \
        --filter=tree:0 \
        --no-checkout \
        https://github.com/sergelogvinov/proxmox-cloud-controller-manager.git \
        proxmox-ccm
      cd proxmox-ccm
      git checkout HEAD charts
      rm -rf .git
    EOF
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm -rf proxmox-ccm"
  }
}

data "helm_template" "proxmox-ccm" {
  name = "proxmox-ccm"
  namespace = "kube-system"

  chart = "${path.module}/proxmox-ccm/charts/proxmox-cloud-controller-manager"

  values = [<<-EOF
    fullnameOverride: proxmox-ccm

    nodeSelector:
      node-role.kubernetes.io/control-plane: ""

    extraArgs:
      - --use-service-account-credentials=false

    config:
      clusters:
        - url: "https://${var.proxmox.host}:8006/api2/json"
          insecure: true
          token_id: ${data.external.proxmox-ccm-token.result.full-tokenid}
          region: ${var.kubernetes.cluster_name}
  EOF
  ]

  set_sensitive {
    name = "config.clusters[0].token_secret"
    value = data.external.proxmox-ccm-token.result.value
  }

  depends_on = [null_resource.proxmox-ccm]
}

data "helm_template" "csr-approver" {
  name = "csr-approver"
  namespace = "kube-system"
  repository = "https://postfinance.github.io/kubelet-csr-approver"

  chart = "kubelet-csr-approver"
  version = "1.0.4"

  values = [<<-EOF
    providerRegex: '${var.kubernetes.cluster_name}-.'
    providerIpPrefixes:
      - ${var.kubernetes.cluster_cidr}
      - ${var.network.cidr}

    maxExpirationSeconds: 86400
    bypassDnsResolution: true

    replicas: 1
    tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
        operator: Equal
      - effect: NoSchedule
        key: node-role.kubernetes.io/control-plane
        operator: Equal
      - key: node.cloudprovider.kubernetes.io/uninitialized
        operator: Equal
        value: "true"
        effect: NoSchedule
  EOF
  ]

  skip_tests = true
}


data "helm_template" "external-dns" {
  name = "external-dns"
  namespace = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"

  chart = "external-dns"
  version = "1.14.2"

  values = [<<-EOF
    provider: cloudflare
    txtOwnerId: homelab
    env:
      - name: CF_API_TOKEN
        valueFrom:
          secretKeyRef:
            name: cloudflare-api-token
            key: api-token
    interval: 5m
    sources:
    - ingress
    domainFilters:
    - "cavarsa.app"
    triggerLoopOnEvent: true
    metrics:
      enabled: false
      serviceMonitor:
        enabled: false
  EOF
  ]

  skip_tests = true
}


data "helm_template" "proxmox-ccm-csi-plugin" {
  name = "csi-proxmox"
  namespace = "csi-proxmox"
  verify = false
  repository = "oci://ghcr.io/sergelogvinov/charts/"
  chart = "proxmox-csi-plugin"

  version = "0.1.16"

  values = [<<-EOF
    fullnameOverride: csi-proxmox
    config:
      clusters:
        - url: "https://${var.proxmox.host}:8006/api2/json"
          insecure: true
          token_id: ${data.external.proxmox-ccm-token.result.full-tokenid}
          region: ${var.kubernetes.cluster_name}

    # Deploy CSI controller only on control-plane nodes
    nodeSelector:
      node-role.kubernetes.io/control-plane: ""
    tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule

    # Define storage classes
    # See https://pve.proxmox.com/wiki/Storage
    storageClass:
      - name: proxmox-data-xfs
        storage: hdd
        reclaimPolicy: Delete
        fstype: xfs
  EOF
  ]

  set_sensitive {
    name = "config.clusters[0].token_secret"
    value = data.external.proxmox-ccm-token.result.value
  }

}

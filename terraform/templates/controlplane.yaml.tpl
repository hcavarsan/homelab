machine:
  certSANs:
    - ${control_plane_vip}
    - ${hostname}
    - ${node_ip}

  kubelet:
    extraArgs:
      node-ip: ${node_ip}
      v: 5

    extraConfig:
      serverTLSBootstrap: true
      allowedUnsafeSysctls:
        - net.ipv4.ip_forward
      maxPods: ${available_hosts_per_subnet}

    nodeIP:
      validSubnets:
          - ${node_ip}/32

  network:
    hostname: ${hostname}
    interfaces:
      - interface: eth0
        addresses:
          - ${node_ip}/${element(split("/", network_cidr), 1)}
        vip:
          ip: ${control_plane_vip}

    nameservers: ${jsonencode(network_dns_servers)}

  time:
    servers:
      - time.google.com

  features:
    kubernetesTalosAPIAccess:
      enabled: true
      allowedRoles:
        - os:reader
      allowedKubernetesNamespaces:
        - kube-system
        - default

    kubePrism:
      enabled: true
      port: 7445

cluster:
  discovery:
    enabled: true
    registries:
      kubernetes:
        disabled: false
      service:
        disabled: true

  network:
    dnsDomain: ${kubernetes_cluster_domain}
    podSubnets: ${format("%#v",split(",",pod_cidr))}
    serviceSubnets: ${format("%#v",split(",",service_cidr))}
    cni:
      name: custom

  proxy:
    disabled: true

  externalCloudProvider:
    enabled: true
    manifests:
    - https://raw.githubusercontent.com/hcavarsan/homelab/main/manifests/talos/fluxcd.yaml
    - https://raw.githubusercontent.com/hcavarsan/homelab/main/manifests/talos/fluxcd-install.yaml


  allowSchedulingOnControlPlanes: true

  etcd:
    advertisedSubnets:
      - ${network_cidr}
    extraArgs:
      listen-metrics-urls: http://0.0.0.0:2381

  controllerManager:
    extraArgs:
      node-cidr-mask-size-ipv4: ${new_subnet_bits}



  extraManifests: []

  inlineManifests:
    - name: external-dns
      contents: |-
        apiVersion: v1
        kind: Namespace
        metadata:
            name: external-dns
    - name: cilium
      contents: |-
        apiVersion: v1
        kind: Namespace
        metadata:
            name: cilium
            labels:
              pod-security.kubernetes.io/enforce: "privileged"
    - name: csr-approver
      contents: |-
        ${indent(8, manifests_csr_approver)}
    - name: proxmox-ccm
      contents: |-
        ${indent(8, manifests_promox_ccm)}
    - name: cilium-deploy
      contents: |-
        ${indent(8, manifests_cilium)}
    - name: cilium-lb-pool
      contents: |-
        apiVersion: cilium.io/v2alpha1
        kind: CiliumLoadBalancerIPPool
        metadata:
          name: main-pool
        spec:
          cidrs:
            - cidr: 192.168.68.20/29
    - name: cilium-l2-policy
      contents: |-
        apiVersion: cilium.io/v2alpha1
        kind: CiliumL2AnnouncementPolicy
        metadata:
          name: policy
        spec:
          loadBalancerIPs: true
          interfaces:
            - .*
          nodeSelector:
            matchLabels:
              kubernetes.io/os: linux
    - name: fluxcd
      contents: |-
        apiVersion: v1
        kind: Namespace
        metadata:
            name: flux-system
            labels:
              app.kubernetes.io/instance: flux-system
              app.kubernetes.io/part-of: flux
              pod-security.kubernetes.io/warn: restricted
              pod-security.kubernetes.io/warn-version: latest
    - name: flux-system-secret
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: github-creds
          namespace: flux-system
        data:
          identity: ${base64encode(identity)}
          identity.pub: ${base64encode(identitypub)}
          known_hosts: ${base64encode(knownhosts)}
    - name: flux-vars
      contents: |-
        apiVersion: v1
        kind: ConfigMap
        metadata:
          namespace: flux-system
          name: cluster-settings
        data:
          STORAGE_CLASS: "default-class"
          STORAGE_CLASS_XFS: "xfs-class"
          CLUSTER_0_VIP: ${control_plane_vip}
    - name: cert-manager
      contents: |-
        apiVersion: v1
        kind: Namespace
        metadata:
            name: cert-manager
            labels:
              pod-security.kubernetes.io/enforce: "privileged"
    - name: cloudflare-api-token
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: cloudflare-api-token
          namespace: cert-manager
        data:
          api-token: ${base64encode(cloudflare_token)}
    - name: cloudflare-api-token-external-dns
      contents: |-
        apiVersion: v1
        kind: Secret
        type: Opaque
        metadata:
          name: cloudflare-api-token
          namespace: external-dns
        data:
          api-token: ${base64encode(cloudflare_token)}
    - name: cloudflare-api-cluster-issuer
      contents: |-
         apiVersion: cert-manager.io/v1
         kind: ClusterIssuer
         metadata:
           annotations:
             meta.helm.sh/release-name: cert-manager
             meta.helm.sh/release-namespace: cert-manager
           name: letsencrypt-production
           labels:
             app.kubernetes.io/managed-by: Helm
             meta.helm.sh/release-name: "cert-manager"
             meta.helm.sh/release-namespace: "cert-manager"
         spec:
           acme:
             email: hencavarsan@gmail.com
             preferredChain: ""
             privateKeySecretRef:
               name: cloudflare-issuer-account-key
             server: https://acme-v02.api.letsencrypt.org/directory
             solvers:
             - dns01:
                 cloudflare:
                   apiTokenSecretRef:
                     key: api-token
                     name: cloudflare-api-token
                   email: hencavarsan@gmail.com
    - name: externaldns-deploy
      contents: |-
        ${indent(8, manifests_external_dns)}
    - name: csi-proxmox-deploy
      contents: |-
        ${indent(8, manifests_csi_proxmox)}
    - name: csi-proxmox-ns
      contents: |-
        apiVersion: v1
        kind: Namespace
        metadata:
          name: csi-proxmox
          labels:
            pod-security.kubernetes.io/enforce: privileged
            pod-security.kubernetes.io/audit: baseline
            pod-security.kubernetes.io/warn: baseline
    - name: traefik-ingress-ns
      contents: |-
        apiVersion: v1
        kind: Namespace
        metadata:
            name: traefik-ingress
            labels:
              pod-security.kubernetes.io/enforce: privileged
              pod-security.kubernetes.io/audit: baseline
              pod-security.kubernetes.io/warn: baseline
    - name: traefik-ingress-default-cert
      contents: |-
         apiVersion: cert-manager.io/v1
         kind: Certificate
         metadata:
           name: cavarsa-app
           namespace: traefik-ingress
         spec:
           secretName: cavarsa-app
           issuerRef:
             kind: ClusterIssuer
             name: letsencrypt-production
           commonName: '*.cavarsa.app'
           dnsNames:
             - '*.cavarsa.app'
    - name: traefik-ingress-default-tls
      contents: |-
         apiVersion: traefik.containo.us/v1alpha1
         kind: TLSStore
         metadata:
           name: default
           namespace: traefik-ingress
         spec:
           defaultCertificate:
             secretName: cavarsa-app

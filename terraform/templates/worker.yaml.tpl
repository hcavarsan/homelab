machine:
  certSANs:
    - ${hostname}
    - ${node_ip}

  kubelet:
    extraArgs:
      v: 5
      node-ip: ${node_ip}

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

    nameservers: ${jsonencode(network_dns_servers)}

  time:
    servers:
      - time.google.com

  features:
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

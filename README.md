<p align="center">
    <h1 align="center">HomeLab - Talos Kubernetes on Proxmox.</h1>
</p>
<p align="center">
	<img src="https://img.shields.io/badge/YAML-CB171E.svg?style=flat-square&logo=YAML&logoColor=white" alt="YAML">
	<img src="https://img.shields.io/badge/Terraform-7B42BC.svg?style=flat-square&logo=Terraform&logoColor=white" alt="Terraform">
</p>

<br>
<details>
  <summary>Table of Contents</summary><br>

- [ Overview](#-overview)
- [ Repository Structure](#-repository-structure)
- [ Modules](#-modules)

</details>
<hr>


## Overview

This project is designed to deploy a Talos Kubernetes cluster in a personal homelab environment, with application deployment managed through Flux CD in a GitOps fashion. The setup leverages Terraform for infrastructure provisioning and FluxCD for continuous delivery and management of Kubernetes resources.

Talos is a modern operating system for Kubernetes that provides a secure, immutable platform and simplifies operations. This project uses Talos to bootstrap a Kubernetes cluster on Proxmox VM infrastructure.

Flux CD is used for the GitOps-based management of Kubernetes resources, allowing for automated application deployment and system updates straight from source control.

The server configuration for this setup includes a Ryzen 7 5700G CPU, 64GB DDR5 memory, a 4TB HDD, and a 2TB NVMe drive with Proxmox installed.

---

##  Repository Structure

```sh
└── ./
    ├── kubernetes
    │   ├── apps
    │   │   ├── cert-manager
    │   │   │   ├── cert-manager
    │   │   │   │   ├── app
    │   │   │   │   └── ks.yaml
    │   │   │   ├── kustomization.yaml
    │   │   │   └── namespace.yaml
    │   │   ├── observability
    │   │   │   ├── grafana
    │   │   │   │   ├── app
    │   │   │   │   └── ks.yaml
    │   │   │   ├── kube-prometheus-stack
    │   │   │   │   ├── app
    │   │   │   │   └── ks.yaml
    │   │   │   ├── kustomization.yaml
    │   │   │   └── namespace.yaml
    │   │   └── traefik-ingress
    │   │       ├── kustomization.yaml
    │   │       ├── namespace.yaml
    │   │       └── traefik
    │   │           ├── app
    │   │           └── flux-sync.yaml
    │   └── flux
    │       ├── apps.yaml
    │       ├── config
    │       │   ├── cluster.yaml
    │       │   ├── crds
    │       │   │   └── .gitkeep
    │       │   ├── flux.yaml
    │       │   └── kustomization.yaml
    │       └── repositories
    │           ├── git
    │           │   ├── kustomization.yaml
    │           │   └── local-path-provisioner.yaml
    │           ├── helm
    │           │   ├── grafana.yaml
    │           │   ├── jetstack.yaml
    │           │   ├── kustomization.yml
    │           │   ├── prometheus-community.yaml
    │           │   └── traefik.yaml
    │           ├── kustomization.yaml
    │           └── oci
    │               └── .gitkeep
    ├── manifests
    │   └── talos
    │       ├── fluxcd-install.yaml
    │       └── fluxcd.yaml
    └── terraform
        ├── .gitignore
        ├── .mise.toml
        ├── machines.tf
        ├── main.tf
        ├── manifests.tf
        ├── proxmox.tf
        ├── talos.tf
        ├── templates
        │   ├── controlplane.yaml.tpl
        │   └── worker.yaml.tpl
        └── variables.tf
```

---

##  Modules

<details closed><summary>terraform</summary>

| File                                   | Summary                                                                                                                                                                                                                                                                                                                                                   |
| ---                                    | ---                                                                                                                                                                                                                                                                                                                                                       |
| [main.tf](terraform/main.tf)           | Defines the infrastructure as code using Terraform for provisioning Kubernetes nodes on Proxmox, specifying required providers, backend configuration for state storage, and outputting computed values for machine IPs and cluster limits within the parent repositorys cloud-native home server setup.                                                  |
| [proxmox.tf](terraform/proxmox.tf)     | Manages the provisioning of a Talos VM on Proxmox, including disk image import and VM configuration, and handles the creation and deletion of a Proxmox user token for Kubernetes cloud controller manager authentication within the repositorys infrastructure automation.                                                                               |
| [talos.tf](terraform/talos.tf)         | Generates Talos machine configurations and secrets, applies them to the infrastructure, and manages the Talos client configuration for a Kubernetes cluster, ensuring nodes are provisioned and configured according to specified variables and templates. It also handles the bootstrap process for the initial control plane node.                      |
| [variables.tf](terraform/variables.tf) | Defines infrastructure configuration variables for provisioning a Kubernetes cluster, including Proxmox virtualization details, Talos OS settings, network parameters, and Kubernetes cluster specifications, with validations to ensure the integrity of the values provided.                                                                            |
| [machines.tf](terraform/machines.tf)   | Defines virtual machines within a Proxmox environment, configuring compute resources and network settings to deploy Kubernetes nodes running TalOS. It leverages Terraform to automate the provisioning of the infrastructure necessary for the Kubernetes cluster setup.                                                                                 |
| [manifests.tf](terraform/manifests.tf) | Enables the deployment and configuration of critical Kubernetes networking and cloud integration components using Terraform, including Cilium for network policies and services, Proxmox cloud controller manager for cluster interaction, CSR approver for node certificate management, ExternalDNS for DNS updates, and Proxmox CSI plugin for storage. |
| [.mise.toml](terraform/.mise.toml)     | Maintains the version specification for Terraform within the repositorys infrastructure as code setup, ensuring consistent tooling across different environments and contributors for provisioning and managing the underlying cloud resources.                                                                                                           |

</details>

<details closed><summary>terraform.templates</summary>

| File                                                               | Summary                                                                                                                                                                                                                                                                                                                    |
| ---                                                                | ---                                                                                                                                                                                                                                                                                                                        |
| [worker.yaml.tpl](terraform/templates/worker.yaml.tpl)             | Generates a Terraform template for Kubernetes worker node configuration, specifying network settings, kubelet arguments, and cluster discovery options, tailored for deployment in a Talos-managed infrastructure with support for an external cloud provider.                                                             |
| [controlplane.yaml.tpl](terraform/templates/controlplane.yaml.tpl) | Defines the configuration template for the control plane nodes in a Kubernetes cluster, including network settings, kubelet parameters, and various Kubernetes features like API access and CNI options. It also specifies custom manifests for cluster components and external integrations like FluxCD and cert-manager. |

</details>

<details closed><summary>manifests.talos</summary>

| File                                                       | Summary                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ---                                                        | ---                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| [fluxcd.yaml](manifests/talos/fluxcd.yaml)                 | Within `apps/cert-manager`, the files manage the deployment of cert-manager, a tool for automating the management and issuance of TLS certificates. The `kustomization.yaml` and `namespace.yaml` establish the Kubernetes resources and namespace configuration, while the `app` directory likely contains the application-specific configurations and `ks.yaml` for Kubernetes manifests.2. **ObservabilityThe `observability` subdirectory houses applications for monitoring and observability. This includes:-`grafana` for analytics and monitoring dashboards. -`kube-prometheus-stack` for a comprehensive monitoring solution that bundles Prometheus, Alertmanager, and related components. Each of these applications has its own `app` directory and `ks.yaml` file, indicating Kubernetes manifests, and the `kustomization.yaml` and `namespace.yaml` files are used for setting up the observability namespace and resource management.3. **Traefik IngressIn `apps/traefik-ingress`, the configuration is focused on setting up Traefik as an ingress controller, which routes traffic to services within the Kubernetes cluster. The `kustomization.yaml` and `namespace.yaml` handle the Kubernetes setup, while `flux-sync.yaml` within the `traefik` directory |
| [fluxcd-install.yaml](manifests/talos/fluxcd-install.yaml) | Defines automated deployment policies for the homelab Kubernetes environment using Flux CD, specifying synchronization intervals, pruning options, and source references for Git and OCI repositories. It also customizes Flux components through patches, enhancing performance and adding support for Terraform resources.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

</details>

<details closed><summary>kubernetes.flux</summary>

| File                                   | Summary                                                                                                                                                                                                                                                                                   |
| ---                                    | ---                                                                                                                                                                                                                                                                                       |
| [apps.yaml](kubernetes/flux/apps.yaml) | Defines the automated deployment process for cluster applications, specifying a 10-minute synchronization interval with the GitRepository source named homelab. It enables pruning of resources and leverages a ConfigMap for variable substitution within the kubernetes/apps directory. |

</details>

<details closed><summary>kubernetes.flux.config</summary>

| File                                                            | Summary                                                                                                                                                                                                                                                                                                                                          |
| ---                                                             | ---                                                                                                                                                                                                                                                                                                                                              |
| [flux.yaml](kubernetes/flux/config/flux.yaml)                   | Defines an OCIRepository resource for syncing Flux manifests and a Kustomization resource for applying configurations with custom patches, such as performance tuning and feature enablement, to the Flux controllers within the flux-system namespace.                                                                                          |
| [kustomization.yaml](kubernetes/flux/config/kustomization.yaml) | Defines a Kustomization resource that orchestrates the application of Flux configuration and cluster-wide settings by including both `flux.yaml` and `cluster.yaml` as part of the Kubernetes resource management process within the repositorys continuous deployment pipeline.                                                                 |
| [cluster.yaml](kubernetes/flux/config/cluster.yaml)             | Defines a GitRepository resource named homelab within the Flux CD configuration, specifying synchronization details with the GitHub repository at a 30-minute interval. It also configures a Kustomization resource for managing the cluster's state, referencing the defined GitRepository and applying configurations from the specified path. |

</details>

<details closed><summary>kubernetes.flux.repositories</summary>

| File                                                                  | Summary                                                                                                                                                                                                                                        |
| ---                                                                   | ---                                                                                                                                                                                                                                            |
| [kustomization.yaml](kubernetes/flux/repositories/kustomization.yaml) | Defines a Kustomization resource that orchestrates the inclusion of Git and Helm repository configurations, streamlining the management of application sources and dependencies within the Kubernetes clusters continuous deployment pipeline. |

</details>

<details closed><summary>kubernetes.flux.repositories.helm</summary>

| File                                                                                     | Summary                                                                                                                                                                                                                                                                                                                             |
| ---                                                                                      | ---                                                                                                                                                                                                                                                                                                                                 |
| [prometheus-community.yaml](kubernetes/flux/repositories/helm/prometheus-community.yaml) | Defines a Helm repository resource for the Prometheus Community chart collection within the Flux CD configuration, facilitating automated retrieval and management of Prometheus-related Helm charts at a regular 5-minute interval from a specified OCI registry.                                                                  |                                 |
| [grafana.yaml](kubernetes/flux/repositories/helm/grafana.yaml)                           | Defines a Helm repository resource for integrating Grafanas Helm charts into the cluster, specifying the repository URL and the synchronization interval within the Flux CD-driven continuous deployment pipeline. It ensures Grafanas Helm charts are regularly updated and available for deployment in the flux-system namespace. |
| [kustomization.yml](kubernetes/flux/repositories/helm/kustomization.yml)                 | Defines a Kustomization resource that aggregates multiple Helm repository configurations, enabling the management of Helm releases for applications such as Jetstack, Traefik, Prometheus, and Grafana within the repositorys Kubernetes infrastructure.                                                                            |
| [jetstack.yaml](kubernetes/flux/repositories/helm/jetstack.yaml)                         | Defines a Helm repository resource for integrating Jetstacks Helm charts within the Flux CD pipeline, specifying the retrieval interval and source URL. It facilitates automated updates and synchronization of Jetstack-related Kubernetes resources in the flux-system namespace.                                                 |
| [traefik.yaml](kubernetes/flux/repositories/helm/traefik.yaml)                           | Defines a Helm repository resource for the Traefik charts within the Flux CD configuration, enabling automated retrieval and management of Traefiks Helm charts at a regular interval of 10 minutes for the Kubernetes cluster.                                                                                                     |

</details>

<details closed><summary>kubernetes.flux.repositories.git</summary>

| File                                                                                        | Summary                                                                                                                                                                                                                                                                                                                          |
| ---                                                                                         | ---                                                                                                                                                                                                                                                                                                                              |
| [kustomization.yaml](kubernetes/flux/repositories/git/kustomization.yaml)                   | Defines a Kustomization resource that manages the deployment of the local-path-provisioner component within the Kubernetes cluster, as part of the GitOps workflow orchestrated by Flux. It streamlines updates and synchronization of this specific cluster resource from the repository.                                       |
| [local-path-provisioner.yaml](kubernetes/flux/repositories/git/local-path-provisioner.yaml) | Defines a GitRepository resource named local-path-provisioner within the flux-system namespace, specifying synchronization parameters for a Kubernetes deployment chart from the rancher/local-path-provisioner GitHub repository, with a 30-minute polling interval and a filter to only include the specified chart directory. |

</details>

<details closed><summary>kubernetes.apps.cert-manager</summary>

| File                                                                  | Summary                                                                                                                                                                                                                                                              |
| ---                                                                   | ---                                                                                                                                                                                                                                                                  |
| [kustomization.yaml](kubernetes/apps/cert-manager/kustomization.yaml) | Defines the resource composition for the cert-manager application within the Kubernetes cluster, orchestrating the deployment order by first applying the namespace configuration followed by the cert-manager specific customizations.                              |
| [namespace.yaml](kubernetes/apps/cert-manager/namespace.yaml)         | Defines a Kubernetes namespace for the cert-manager application, ensuring its resources are logically isolated within the cluster. It also includes a label to prevent automatic pruning by Flux, the GitOps continuous delivery solution used in this architecture. |

</details>

<details closed><summary>kubernetes.apps.cert-manager.cert-manager</summary>

| File                                                         | Summary                                                                                                                                                                                                                                                                                   |
| ---                                                          | ---                                                                                                                                                                                                                                                                                       |
| [ks.yaml](kubernetes/apps/cert-manager/cert-manager/ks.yaml) | Defines a Kustomization resource for managing the deployment of cert-manager within the Kubernetes cluster, specifying the synchronization source, pruning behavior, health checks, and update intervals to ensure the applications continuous delivery through Flux CDs GitOps workflow. |

</details>

<details closed><summary>kubernetes.apps.cert-manager.cert-manager.app</summary>

| File                                                                                   | Summary                                                                                                                                                                                                                                                                                                                |
| ---                                                                                    | ---                                                                                                                                                                                                                                                                                                                    |
| [kustomization.yaml](kubernetes/apps/cert-manager/cert-manager/app/kustomization.yaml) | Defines the Kustomization configuration for the cert-manager application within the Kubernetes cluster, specifying the namespace and including the Helm release resource for deployment management.                                                                                                                    |
| [helmrelease.yaml](kubernetes/apps/cert-manager/cert-manager/app/helmrelease.yaml)     | Defines a HelmRelease for cert-manager, automating its deployment within the Kubernetes cluster. It references the jetstack Helm repository, specifies version and upgrade strategies, and configures DNS settings for cert-managers operation. The release ensures CRDs are installed and manages namespace creation. |

</details>

<details closed><summary>kubernetes.apps.observability</summary>

| File                                                                   | Summary                                                                                                                                                                                                                                                                     |
| ---                                                                    | ---                                                                                                                                                                                                                                                                         |
| [kustomization.yaml](kubernetes/apps/observability/kustomization.yaml) | Defines the resource aggregation for the observability applications within the Kubernetes cluster, including the creation of a dedicated namespace and the deployment of Grafana, and the kube-prometheus-stack for monitoring and metrics visualization.           |
| [namespace.yaml](kubernetes/apps/observability/namespace.yaml)         | Defines a Kubernetes namespace named observability that is exempt from automatic pruning by FluxCD, ensuring that the namespace and its resources persist even if they are no longer defined in the source code. This namespace likely houses monitoring and logging tools. |

</details>

<details closed><summary>kubernetes.apps.observability.kube-prometheus-stack</summary>

| File                                                                   | Summary                                                                                                                                                                                                                                                                                         |
| ---                                                                    | ---                                                                                                                                                                                                                                                                                             |
| [ks.yaml](kubernetes/apps/observability/kube-prometheus-stack/ks.yaml) | Defines the Kustomization resource for the kube-prometheus-stack, orchestrating its deployment within the observability namespace and managing its lifecycle through the Flux CD GitOps workflow, with automated pruning and scheduled synchronization from the specified GitRepository source. |

</details>

<details closed><summary>kubernetes.apps.observability.kube-prometheus-stack.app</summary>

| File                                                                                             | Summary                                                                                                                                                                                                                                                                                                               |
| ---                                                                                              | ---                                                                                                                                                                                                                                                                                                                   |
| [kustomization.yaml](kubernetes/apps/observability/kube-prometheus-stack/app/kustomization.yaml) | Defines the Kustomization configuration for the kube-prometheus-stack application, specifying resources such as the Helm release and generating ConfigMaps for Alertmanager and kube-state-metrics without adding a name suffix hash for easier identification.                                                       |
| [helmrelease.yaml](kubernetes/apps/observability/kube-prometheus-stack/app/helmrelease.yaml)     | Defines a HelmRelease for the kube-prometheus-stack, configuring Prometheus, Alertmanager, and related monitoring components with custom resource definitions, storage options, and relabeling rules for metrics, while disabling kube-proxy in favor of eBPF and setting up ingress for Prometheus and Alertmanager. |

</details>

<details closed><summary>kubernetes.apps.observability.kube-prometheus-stack.app.resources</summary>

| File                                                                                                                 | Summary                                                                                                                                                                                                                                                                                          |
| ---                                                                                                                  | ---                                                                                                                                                                                                                                                                                              |
| [alertmanager.yaml](kubernetes/apps/observability/kube-prometheus-stack/app/resources/alertmanager.yaml)             | Defines the Alertmanager configuration for the kube-prometheus-stack, detailing alert routing, grouping, and notification settings for critical alerts, including integration with the Pushover service for immediate notifications and special handling for heartbeat and informational alerts. |
| [kube-state-metrics.yaml](kubernetes/apps/observability/kube-prometheus-stack/app/resources/kube-state-metrics.yaml) | Defines the configuration for kube-state-metrics within the kube-prometheus-stack, enabling Prometheus monitoring and specifying custom resource metrics for enhanced observability of GitOps Toolkit resources in a Kubernetes cluster. It extends RBAC rules to include Flux CD resources.     |

</details>

<details closed><summary>kubernetes.apps.observability.grafana</summary>

| File                                                     | Summary                                                                                                                                                                                                                                                     |
| ---                                                      | ---                                                                                                                                                                                                                                                         |
| [ks.yaml](kubernetes/apps/observability/grafana/ks.yaml) | Defines a Kustomization resource for deploying Grafana within the observability namespace, managed by Flux CD, with automated pruning and synchronization from a GitRepository named homelab every 30 minutes, and a retry strategy for failed deployments. |

</details>

<details closed><summary>kubernetes.apps.observability.grafana.app</summary>

| File                                                                               | Summary                                                                                                                                                                                                                                                                                                                          |
| ---                                                                                | ---                                                                                                                                                                                                                                                                                                                              |
| [kustomization.yaml](kubernetes/apps/observability/grafana/app/kustomization.yaml) | Enables the deployment of Grafana through a Helm release by defining the necessary Kustomization resource, integrating it into the observability stack of the Kubernetes infrastructure. It streamlines the applications setup within the larger ecosystem of monitoring tools.                                                  |
| [helmrelease.yaml](kubernetes/apps/observability/grafana/app/helmrelease.yaml)     | Defines a HelmRelease for Grafana, specifying deployment strategy, environment variables, Grafana configuration, dashboard providers, pre-configured dashboards, sidecar settings for dynamic dashboard and datasource loading, plugins, service monitoring, ingress rules, persistent storage, and topology spread constraints. |

</details>

<details closed><summary>kubernetes.apps.traefik-ingress</summary>

| File                                                                     | Summary                                                                                                                                                                                                                                                                                  |
| ---                                                                      | ---                                                                                                                                                                                                                                                                                      |
| [kustomization.yaml](kubernetes/apps/traefik-ingress/kustomization.yaml) | Defines the Kustomization configuration for the Traefik Ingress setup within the Kubernetes cluster, specifying the namespace creation and the synchronization of Traefik configuration through Flux, aligning with the GitOps practices adopted in the repositorys architecture.        |
| [namespace.yaml](kubernetes/apps/traefik-ingress/namespace.yaml)         | Defines the Kubernetes namespace for the Traefik Ingress resources, ensuring they are organized within a dedicated namespace. The namespace is labeled to prevent automatic pruning by FluxCD, indicating a manual management preference for the lifecycle of this namespaces resources. |

</details>

<details closed><summary>kubernetes.apps.traefik-ingress.traefik</summary>

| File                                                                     | Summary                                                                                                                                                                                                                          |
| ---                                                                      | ---                                                                                                                                                                                                                              |
| [flux-sync.yaml](kubernetes/apps/traefik-ingress/traefik/flux-sync.yaml) | Defines the synchronization parameters for the Traefik ingress controller within the Kubernetes cluster, specifying the source repository, sync frequency, and directory path for the applications resources managed by Flux CD. |

</details>

<details closed><summary>kubernetes.apps.traefik-ingress.traefik.app</summary>

| File                                                                                 | Summary                                                                                                                                                                                                                                                                                    |
| ---                                                                                  | ---                                                                                                                                                                                                                                                                                        |
| [ingress.yaml](kubernetes/apps/traefik-ingress/traefik/app/ingress.yaml)             | Defines an Ingress resource for the Traefik ingress controller, specifying routing rules for secure web traffic to the Traefik service within the Kubernetes cluster, ensuring encrypted connections and load balancing across the specified entry points.                                 |
| [kustomization.yaml](kubernetes/apps/traefik-ingress/traefik/app/kustomization.yaml) | Defines the Kustomization configuration for the Traefik Ingress Controller within the `traefik-ingress` namespace, incorporating external CRDs from the Traefik Helm chart and local resource definitions for deployment within the Kubernetes cluster.                                    |
| [helm-release.yaml](kubernetes/apps/traefik-ingress/traefik/app/helm-release.yaml)   | Defines a HelmRelease for Traefik, specifying its deployment within the Kubernetes cluster managed by Flux. It configures Traefik as the default ingress controller, sets resource limits, enables access logs in JSON format, and outlines the Helm chart version and repository details. |

</details>


README generated by https://github.com/eli64s/readme-ai

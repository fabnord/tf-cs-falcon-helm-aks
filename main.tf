provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "aks-cluster" {
  name                = var.azure_aks_name
  resource_group_name = var.azure_aks_resource_group
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = data.azurerm_kubernetes_cluster.aks-cluster.name
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

locals {
  falcon_ccid = lower(var.falcon_cid)
  falcon_cid  = lower(substr(var.falcon_cid, 0, 32))
}

resource "kubernetes_namespace" "cs-falcon-kpagent" {
  metadata {
    name = "falcon-kpagent"
  }
}

resource "kubernetes_namespace" "cs-falcon-namespace" {
  metadata {
    name = "falcon-system"
  }
}

resource "kubernetes_secret" "cs-cr-pullsecret" {
  metadata {
    name      = "cs-cr-pullsecret"
    namespace = kubernetes_namespace.cs-falcon-namespace.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "registry.crowdstrike.com" = {
          "username" = "fc-${local.falcon_cid}"
          "password" = "${var.falcon_sensor_cr_token}"
          "auth"     = base64encode("fc-${local.falcon_cid}:${var.falcon_sensor_cr_token}")
        }
      }
    })
  }
}

resource "helm_release" "cs-falcon-kpagent" {
  name       = "cs-falcon-kpagent"
  chart      = "cs-k8s-protection-agent"
  repository = "https://registry.crowdstrike.com/kpagent-helm"
  namespace  = kubernetes_namespace.cs-falcon-kpagent.metadata[0].name

  values = [<<-EOF
    nameOverride: "cs-falcon-kpagent"
    crowdstrikeConfig:
      clientID: ${var.falcon_cliend_id}
      clientSecret: ${var.falcon_client_secret}
      clusterName: ${data.azurerm_kubernetes_cluster.aks-cluster.name}
      env: ${var.falcon_cloud_region}
      cid: ${local.falcon_cid}
      dockerAPIToken: ${var.falcon_kpa_cr_token}
    EOF
  ]
}

resource "helm_release" "cs-falcon-sensor" {
  name       = "cs-falcon-sensor"
  chart      = "falcon-sensor"
  repository = "https://crowdstrike.github.io/falcon-helm"
  namespace  = kubernetes_namespace.cs-falcon-namespace.metadata[0].name

  values = [<<-EOF
    falcon:
      cid: ${local.falcon_ccid}
      feature: enableLog
      trace: debug
    node:
      image:
        repository: registry.crowdstrike.com/falcon-sensor/us-1/release/falcon-sensor
        tag: 6.47.0-14408.falcon-linux.x86_64.Release.US-1
        pullSecrets: ${kubernetes_secret.cs-cr-pullsecret.metadata[0].name}
    EOF
  ]
}

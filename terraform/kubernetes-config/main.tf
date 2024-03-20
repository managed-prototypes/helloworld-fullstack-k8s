terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.36.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.27.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_pat
}

data "digitalocean_kubernetes_cluster" "primary" {
  name = var.cluster_name
}

resource "local_file" "kubeconfig" {
  depends_on = [var.cluster_id]
  count      = var.write_kubeconfig ? 1 : 0
  content    = data.digitalocean_kubernetes_cluster.primary.kube_config[0].raw_config
  filename   = "${path.root}/k8s-cluster-access.yaml"
}

provider "kubernetes" {
  host  = data.digitalocean_kubernetes_cluster.primary.endpoint
  token = data.digitalocean_kubernetes_cluster.primary.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate
  )
}

provider "kubectl" {
  host                   = data.digitalocean_kubernetes_cluster.primary.endpoint
  cluster_ca_certificate = base64decode(data.digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate)
  token                  = data.digitalocean_kubernetes_cluster.primary.kube_config[0].token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host  = data.digitalocean_kubernetes_cluster.primary.endpoint
    token = data.digitalocean_kubernetes_cluster.primary.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate
    )
  }
}

# ======================== cert manager

resource "kubernetes_namespace" "certsnamespace" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager_release" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.14.4"
  namespace  = kubernetes_namespace.certsnamespace.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_secret_v1" "letsencrypt_do_dns" {
  metadata {
    name      = "letsencrypt-do-dns"
    namespace = kubernetes_namespace.certsnamespace.metadata[0].name
  }

  data = {
    access-token = var.do_pat_cert_manager
  }
}

data "kubectl_file_documents" "clusterissuer" {
  content = file("${path.module}/clusterissuer.yaml")
}

resource "kubectl_manifest" "clusterissuer" {
  depends_on = [kubernetes_namespace.certsnamespace, helm_release.cert_manager_release]
  for_each   = data.kubectl_file_documents.clusterissuer.manifests
  yaml_body  = each.value
}

# ======================== app

resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
}

data "kubectl_file_documents" "web" {
  content = file("${path.module}/web.yaml")
}

resource "kubectl_manifest" "web" {
  depends_on = [kubernetes_namespace.app]
  for_each   = data.kubectl_file_documents.web.manifests
  yaml_body  = each.value
}


# ======================== ingress traefik

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "traefik" {
  depends_on = [kubernetes_namespace.traefik]
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "26.0.0"
  namespace  = "traefik"
}

data "kubectl_file_documents" "ingress" {
  content = file("${path.module}/ingress.yaml")
}

resource "kubectl_manifest" "ingress" {
  depends_on = [kubernetes_namespace.traefik, helm_release.traefik]
  for_each   = data.kubectl_file_documents.ingress.manifests
  yaml_body  = each.value
}

# Note: this requires k8s cluster to be running, otherwise plan/apply will fail.
data "kubernetes_service_v1" "traefik_service" {
  depends_on = [helm_release.traefik]
  metadata {
    name = "traefik"
    namespace = "traefik"
  }
}

resource "digitalocean_record" "a_record" {
  domain = "prototyping.quest"
  type = "A"
  name = "web-k8s"
  value = data.kubernetes_service_v1.traefik_service.status.0.load_balancer.0.ingress.0.ip
}
# ======================== ingress nginx

# resource "kubernetes_namespace" "icnamespace" {
#   metadata {
#     name = "icnamespace"
#   }
# }

# resource "helm_release" "icrelease" {
#   name       = "nginx-ingress"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   version    = "4.9.1"
#   namespace  = kubernetes_namespace.app.metadata[0].name # TODO: change

#   set {
#     name  = "controller.ingressClassResource.default"
#     value = "true"
#   }
# }

# resource "kubernetes_ingress_v1" "wwwingress" {
#   metadata {
#     name      = "wwwingress"
#     namespace = kubernetes_namespace.app.metadata[0].name
#   }

#   spec {
#     ingress_class_name = "nginx"

#     rule {
#       host = "web-k8s.prototyping.quest"

#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"

#           backend {
#             service {
#               name = "web-service"

#               port {
#                 number = 80
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

# data "kubernetes_service" "lbicservice" {
#   metadata {
#     name      = "${helm_release.icrelease.name}-${helm_release.icrelease.chart}-controller"
#     namespace = kubernetes_namespace.app.metadata[0].name
#   }
# }

# resource "digitalocean_record" "a_record" {
#   domain = "prototyping.quest"
#   type   = "A"
#   name   = "web-k8s"
#   value  = data.kubernetes_service.lbicservice.status[0].load_balancer[0].ingress[0].ip
# }

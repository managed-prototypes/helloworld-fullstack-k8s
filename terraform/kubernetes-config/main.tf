terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.36.0"
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

data "http" "cert_manager_yaml" {
  # Lastest version is listed here: https://github.com/cert-manager/cert-manager/releases/latest
  url = "https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml"
}

resource "kubectl_manifest" "cert_manager" {
  yaml_body = data.http.cert_manager_yaml.response_body
}

resource "kubectl_manifest" "namespace" {
  yaml_body = file("${path.module}/namespace.yaml")
}

resource "kubectl_manifest" "web" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = file("${path.module}/web.yaml")
}

# # resource "kubernetes_deployment" "test" {
# #   metadata {
# #     name      = "test"
# #     namespace = kubernetes_namespace.test.metadata.0.name
# #   }
# #   spec {
# #     replicas = 2
# #     selector {
# #       match_labels = {
# #         app = "test"
# #       }
# #     }
# #     template {
# #       metadata {
# #         labels = {
# #           app = "test"
# #         }
# #       }
# #       spec {
# #         container {
# #           image = "hashicorp/http-echo"
# #           name  = "http-echo"
# #           args  = ["-text=test"]

# #           resources {
# #             limits = {
# #               memory = "512M"
# #               cpu    = "1"
# #             }
# #             requests = {
# #               memory = "256M"
# #               cpu    = "50m"
# #             }
# #           }
# #         }
# #       }
# #     }
# #   }
# # }

# # resource "kubernetes_service" "test" {
# #   metadata {
# #     name      = "test-service"
# #     namespace = kubernetes_namespace.test.metadata.0.name
# #   }
# #   spec {
# #     selector = {
# #       app = kubernetes_deployment.test.metadata.0.name
# #     }

# #     port {
# #       port = 5678
# #     }
# #   }
# # }

# # resource "helm_release" "nginx_ingress" {
# #   name      = "nginx-ingress-controller"
# #   namespace = kubernetes_namespace.test.metadata.0.name

# #   repository = "https://charts.bitnami.com/bitnami"
# #   chart      = "nginx-ingress-controller"

# #   set {
# #     name  = "service.type"
# #     value = "LoadBalancer"
# #   }
# #   set {
# #     name  = "service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-name"
# #     value = format("%s-nginx-ingress", var.cluster_name)
# #   }
# # }

# # resource "kubernetes_ingress_v1" "test_ingress" {
# #   wait_for_load_balancer = true
# #   metadata {
# #     name      = "test-ingress"
# #     namespace = kubernetes_namespace.test.metadata.0.name
# #     annotations = {
# #       "kubernetes.io/ingress.class"          = "nginx"
# #       "ingress.kubernetes.io/rewrite-target" = "/"
# #     }
# #   }

# #   spec {
# #     rule {
# #       http {
# #         path {
# #           backend {
# #             service {
# #               name = kubernetes_service.test.metadata.0.name
# #               port {
# #                 number = 5678
# #               }
# #             }
# #           }

# #           path = "/test"
# #         }
# #       }
# #     }
# #   }
# # }


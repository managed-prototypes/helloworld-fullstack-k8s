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

resource "kubectl_manifest" "clusterissuer" {
  depends_on = [kubernetes_namespace.certsnamespace, helm_release.cert_manager_release]
  yaml_body  = file("${path.module}/clusterissuer.yaml")
}

# ======================== www

resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
}

resource "kubectl_manifest" "web" {
  depends_on = [kubernetes_namespace.app]
  yaml_body  = file("${path.module}/web.yaml")
}


# ======================== ingress

# resource "kubernetes_namespace" "traefik" {
#   metadata {
#     name = "traefik"
#   }
# }

# resource "helm_release" "traefik" {
#   depends_on = [kubernetes_namespace.traefik]
#   name       = "traefik"
#   repository = "https://traefik.github.io/charts"
#   chart      = "traefik"
#   version    = "26.0.0"
#   namespace  = "traefik"
# }

# resource "kubectl_manifest" "ingress" {
#   depends_on = [kubernetes_namespace.traefik, helm_release.traefik]
#   yaml_body  = file("${path.module}/ingress.yaml")
# }

# data "digitalocean_loadbalancer" "example" {
#   name = "web-k8s"
# }

# output "lb_output" {
#   value = data.digitalocean_loadbalancer.example.ip
# }

# resource "digitalocean_record" "a_record" {
#   domain = "prototyping.quest"
#   type = "A"
#   name = "web-k8s"
#   value = "188.166.134.137" # TODO: use ingress IP address: kubectl get services -n traefik
# }

# ======================== ingress from dev.to article

resource "kubernetes_namespace" "icnamespace" {
  metadata {
    name = "icnamespace"
  }
}

resource "helm_release" "icrelease" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.9.1"
  namespace  = kubernetes_namespace.icnamespace.metadata[0].name

  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }
}

resource "kubernetes_ingress_v1" "wwwingress" {
  metadata {
    name      = "wwwingress"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "web-k8s.prototyping.quest"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "web-service"

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

data "kubernetes_service" "lbicservice" {
  metadata {
    name      = "${helm_release.icrelease.name}-${helm_release.icrelease.chart}-controller"
    namespace = kubernetes_namespace.icnamespace.metadata[0].name
  }
}

resource "digitalocean_record" "a_record" {
  domain = "prototyping.quest"
  type   = "A"
  name   = "web-k8s"
  value  = data.kubernetes_service.lbicservice.status[0].load_balancer[0].ingress[0].ip
}

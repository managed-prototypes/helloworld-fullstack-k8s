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


resource "kubernetes_manifest" "clusterissuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = "clusterissuer"
    }

    spec = {
      acme = {
        email  = var.acme_email
        server = var.acme_server

        privateKeySecretRef = {
          name = "clusterissuer-secret"
          # name = "letsencrypt-issuer-account-key" # TODO: remove
        }

        solvers = [{
          dns01 = {
            digitalocean = {
              tokenSecretRef = {
                name = kubernetes_secret_v1.letsencrypt_do_dns.metadata[0].name
                key  = "access-token"
              }
            }
          }
        }]
      }
    }
  }
}

resource "kubectl_manifest" "namespace" {
  yaml_body = file("${path.module}/namespace.yaml")
}

resource "kubectl_manifest" "web" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = file("${path.module}/web.yaml")
}

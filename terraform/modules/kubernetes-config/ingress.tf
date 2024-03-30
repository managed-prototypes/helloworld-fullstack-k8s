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
  timeout    = 900 # seconds
}

data "kubectl_file_documents" "ingress" {
  content = file("${path.module}/ingress.yaml")
}

resource "kubectl_manifest" "ingress" {
  depends_on = [helm_release.traefik]
  for_each   = data.kubectl_file_documents.ingress.manifests
  yaml_body  = each.value
}

data "kubernetes_service_v1" "traefik" {
  depends_on = [helm_release.traefik]
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
}

resource "digitalocean_record" "webapp" {
  domain = "prototyping.quest"
  type   = "A"
  name   = "helloworld"
  value  = data.kubernetes_service_v1.traefik.status.0.load_balancer.0.ingress.0.ip
}

resource "digitalocean_record" "backend" {
  domain = "prototyping.quest"
  type   = "A"
  name   = "helloworld-api"
  value  = data.kubernetes_service_v1.traefik.status.0.load_balancer.0.ingress.0.ip
}

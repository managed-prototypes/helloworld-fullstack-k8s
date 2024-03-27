
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
  timeout    = 900 # seconds

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

data "kubectl_file_documents" "webapp" {
  content = file("${path.module}/webapp.yaml")
}

resource "kubectl_manifest" "webapp" {
  depends_on = [kubernetes_namespace.applications, kubernetes_secret_v1.dockerconfigjson-ghcr]
  for_each   = data.kubectl_file_documents.webapp.manifests
  yaml_body  = each.value
}

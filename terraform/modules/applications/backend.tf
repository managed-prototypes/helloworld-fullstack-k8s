data "kubectl_file_documents" "backend" {
  content = file("${path.module}/backend.yaml")
}

resource "kubectl_manifest" "backend" {
  depends_on = [kubernetes_namespace.applications, kubernetes_secret_v1.dockerconfigjson-ghcr]
  for_each   = data.kubectl_file_documents.backend.manifests
  yaml_body  = each.value
}

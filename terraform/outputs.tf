output "kubeconfig_path" {
  value = var.write_kubeconfig ? abspath("${path.root}/kubernetes-cluster-access.yaml") : "none"
}

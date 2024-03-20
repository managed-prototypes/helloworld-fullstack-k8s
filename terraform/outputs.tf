output "cluster_name" {
  value = module.kubernetes-cluster.cluster_name
}

output "kubeconfig_path" {
  value = var.write_kubeconfig ? abspath("${path.root}/kubernetes-cluster-access.yaml") : "none"
}

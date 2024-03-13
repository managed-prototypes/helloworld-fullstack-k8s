variable "do_pat" {
  type = string
}

variable "application_name" {
  # Note: Will be used for DNS records, use hypens.
  default = "web-k8s"
}

variable "cluster_version" {
  default = "1.29"
}

variable "worker_count" {
  default = 2
}

variable "worker_size" {
  default = "s-1vcpu-2gb"
}

variable "write_kubeconfig" {
  type        = bool
  default     = false
}

variable "do_pat" {
  type      = string
  sensitive = true
}

variable "do_pat_cert_manager" {
  type      = string
  sensitive = true
}

variable "ghcr_pat" {
  type      = string
  sensitive = true
}

variable "cluster_version" {
  default = "1.29"
}

variable "worker_count" {
  default = 2
}

variable "worker_size" {
  default = "s-4vcpu-8gb"
}

variable "write_kubeconfig" {
  type    = bool
  default = false
}

variable "acme_email" {
  type        = string
  default     = "vladimir@logachev.dev"
}

variable "acme_server" {
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

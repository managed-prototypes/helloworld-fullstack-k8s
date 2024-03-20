variable "do_pat" {
  type      = string
  sensitive = true
}

variable "do_pat_cert_manager" {
  type      = string
  sensitive = true
}

variable "cluster_name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "write_kubeconfig" {
  type    = bool
  default = false
}

variable "acme_email" {
  type        = string
  description = "Email address used for ACME cert registration and renewal proces"
}

variable "acme_server" {
  type        = string
  description = "Address used to configure ClusterIssuer for ACME cert request verification"
}

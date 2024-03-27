variable "do_pat" {
  type      = string
  sensitive = true
}

variable "ghcr_pat" {
  type      = string
  sensitive = true
}

variable "cluster_name" {
  type = string
}

variable "github_username" {
  type = string
}

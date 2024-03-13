variable "do_pat" {
  
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

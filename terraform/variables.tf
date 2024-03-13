variable "do_pat" {
  type = string
}

variable "application_name" {
  # Note: Will be used for DNS records, use hypens.
  default = "web-k8s"
}

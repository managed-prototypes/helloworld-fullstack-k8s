terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://ams3.digitaloceanspaces.com"
    }
    # Note: Specified here, because function calls and variables are not allowed for this configuration
    key                         = "terraform/fullstack-k8s/terraform.tfstate"
    bucket                      = "managed-prototypes"
    region                      = "us-east-1" # Note: Incorrect for DO, but the field is required by TF
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

resource "random_id" "cluster_name" {
  byte_length = 5
}

locals {
  cluster_name = "tf-k8s-${random_id.cluster_name.hex}"
}

module "kubernetes-cluster" {
  source = "./modules/kubernetes-cluster"

  do_pat = var.do_pat

  cluster_name    = local.cluster_name
  cluster_region  = "ams3"
  cluster_version = var.cluster_version

  worker_size  = var.worker_size
  worker_count = var.worker_count
}

module "kubernetes-config" {
  source = "./modules/kubernetes-config"

  do_pat              = var.do_pat
  do_pat_cert_manager = var.do_pat_cert_manager

  cluster_name = module.kubernetes-cluster.cluster_name
  cluster_id   = module.kubernetes-cluster.cluster_id

  write_kubeconfig = var.write_kubeconfig

  acme_email  = var.acme_email
  acme_server = var.acme_server
}

module "applications" {
  source          = "./modules/applications"
  do_pat          = var.do_pat
  ghcr_pat        = var.ghcr_pat
  cluster_name    = module.kubernetes-cluster.cluster_name
  github_username = "vladimirlogachev"
}



terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.36"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://ams3.digitaloceanspaces.com"
    }
    # Note: Specified here, because function calls and variables are not allowed for this configuration
    key                         = "terraform/web-k8s/terraform.tfstate"
    bucket                      = "managed-prototypes"
    region                      = "us-east-1" # Note: Incorrect for DO, but the field is required by TF
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

provider "digitalocean" {
  token = var.do_pat
}

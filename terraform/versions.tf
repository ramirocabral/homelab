terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket = "tfstate"
    key    = "lab/terraform.tfstate"
    region = "garage"

    endpoints      = { s3 = "http://192.168.9.5:30188" }
    use_path_style = true

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

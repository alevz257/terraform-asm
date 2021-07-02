terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.66.1"
    }
  }
  
  backend "gcs" {
      bucket = "alevz-demo-tf-1"
      prefix = "terraform/asm-demo-state"
  }

  required_version = "~> 1.0.1"
}


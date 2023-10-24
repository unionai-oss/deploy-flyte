terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.41.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.41.0"
    }
  }

  required_version = ">= 1.3.0"

  backend "gcs" {
    bucket = "flyte-tf-state"
  }
}

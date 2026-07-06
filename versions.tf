terraform {
  required_providers {
    ns = {
      source  = "nullstone-io/ns"
      version = "~> 0.11.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 6.14"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

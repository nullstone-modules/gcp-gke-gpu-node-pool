data "ns_workspace" "this" {}

// Generate a random suffix to ensure uniqueness of resources
resource "random_string" "resource_suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = false
  special = false
}

locals {
  labels     = data.ns_workspace.this.gcp_labels
  k8s_labels = data.ns_workspace.this.k8s_labels
  block_name = data.ns_workspace.this.block_name
}

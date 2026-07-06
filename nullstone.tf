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
  labels        = data.ns_workspace.this.gcp_labels
  stack_name    = data.ns_workspace.this.stack_name
  block_name    = data.ns_workspace.this.block_name
  env_name      = data.ns_workspace.this.env_name
  block_ref     = data.ns_workspace.this.block_ref
  resource_name = "${local.block_ref}-${random_string.resource_suffix.result}"

  resource_labels = {
    nullstone-stack = local.stack_name
    nullstone-block = local.block_name
    nullstone-env   = local.env_name
  }
}

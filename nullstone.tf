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
  labels = data.ns_workspace.this.gcp_labels

  // node_labels are applied to the Kubernetes node objects via node_config.labels. Built explicitly
  // (rather than passing k8s_labels straight through) because GKE rejects node labels under the
  // reserved kubernetes.io / k8s.io namespaces, e.g. the app.kubernetes.io/* recommended labels.
  node_labels = {
    environment        = local.env_name
    owner              = local.labels["owner"]
    project            = local.stack_name
    dataclassification = try(local.labels["dataclassification"], null)
    application        = local.block_name

    "nullstone.io/env"   = local.env_name
    "nullstone.io/stack" = local.stack_name
    "nullstone.io/block" = local.block_name
  }

  stack_name = data.ns_workspace.this.stack_name
  block_name = data.ns_workspace.this.block_name
  env_name   = data.ns_workspace.this.env_name
}

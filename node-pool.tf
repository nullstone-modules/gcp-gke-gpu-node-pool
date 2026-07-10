data "google_compute_zones" "available" {
  project = local.project_id
  region  = local.region
}

locals {
  // GKE caps node pool names at 40 chars and the provider appends a 26-char unique suffix,
  // leaving 14 chars for the prefix. block_name is truncated to fit (the trailing "-" takes 1);
  // trimsuffix avoids a double dash when the truncation lands on one.
  name_prefix = "${trimsuffix(substr(local.block_name, 0, 13), "-")}-"

  // Select the zones to place the node pool.
  // GCP subnets are regional, so every zone available in the cluster's region is reachable
  // from the network. We limit the zones chosen by var.num_node_zones (but this cannot be
  // larger than the total available zones).
  available_zones = data.google_compute_zones.available.names
  zones           = slice(local.available_zones, 0, min(var.num_node_zones, length(local.available_zones)))
}

// GKE automatically taints GPU nodes with `nvidia.com/gpu=present:NoSchedule`, so only pods
// that tolerate the taint (e.g. apps with the gcp-gke-gpu-cores capability) schedule here.
// System workloads (kube-dns, external-secrets) cannot run on this pool — the cluster must
// have at least one untainted pool.
resource "google_container_node_pool" "this" {
  name_prefix = local.name_prefix
  location    = local.region
  cluster     = local.cluster_name
  project     = local.project_id

  initial_node_count = var.min_node_count
  node_locations     = local.zones

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  lifecycle {
    create_before_destroy = true

    ignore_changes = [initial_node_count]

    precondition {
      condition     = local.meets_min_gke_134
      error_message = "GPU node pools with time-slicing on G4 machines require GKE 1.34+, but the cluster is running ${data.google_container_cluster.this.master_version}. Set var.min_master_version = \"1.34\" on the gcp-gke cluster block and apply it first."
    }
  }

  node_config {
    machine_type    = var.machine_type
    spot            = var.spot
    service_account = local.node_service_account_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    labels          = local.k8s_labels
    resource_labels = local.labels
    tags            = ["gke-node", "${local.cluster_name}-gke"]

    disk_size_gb = var.disk_size
    disk_type    = var.disk_type

    guest_accelerator {
      type  = var.accelerator_type
      count = var.accelerator_count

      gpu_driver_installation_config {
        gpu_driver_version = var.gpu_driver_version
      }

      // Time-slicing: each physical GPU is advertised as `max_shared_clients_per_gpu`
      // schedulable `nvidia.com/gpu` slots. Omitted when set to 1 (dedicated GPUs).
      dynamic "gpu_sharing_config" {
        for_each = var.max_shared_clients_per_gpu > 1 ? [1] : []

        content {
          gpu_sharing_strategy       = "TIME_SHARING"
          max_shared_clients_per_gpu = var.max_shared_clients_per_gpu
        }
      }
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  network_config {
    enable_private_nodes = true
  }
}

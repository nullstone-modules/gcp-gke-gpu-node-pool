data "ns_connection" "cluster" {
  name     = "cluster"
  contract = "cluster/gcp/k8s:gke"
}

locals {
  project_id   = data.ns_connection.cluster.outputs.project_id
  region       = data.ns_connection.cluster.outputs.region
  cluster_name = data.ns_connection.cluster.outputs.cluster_name

  // Reuse the cluster's node service account (gcp-gke 0.7.0+). Against older cluster modules
  // this falls back to null, which makes GKE use the default compute service account.
  node_service_account_email = try(data.ns_connection.cluster.outputs.node_service_account_email, null)
}

data "google_container_cluster" "this" {
  name     = local.cluster_name
  location = local.region
  project  = local.project_id
}

locals {
  // GPU time-slicing on G4 machines requires GKE 1.34+.
  // master_version looks like "1.34.1-gke.2178000"; we only need major.minor.
  master_version_parts = split(".", data.google_container_cluster.this.master_version)
  master_major         = tonumber(local.master_version_parts[0])
  master_minor         = tonumber(local.master_version_parts[1])
  meets_min_gke_134    = local.master_major > 1 || (local.master_major == 1 && local.master_minor >= 34)
}

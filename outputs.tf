output "cluster_name" {
  value       = local.cluster_name
  description = "string ||| The name of the GKE cluster this node pool belongs to."
}

output "node_pool_name" {
  value       = google_container_node_pool.this.name
  description = "string ||| The name of the GPU node pool."
}

output "node_selector" {
  value       = { "cloud.google.com/gke-nodepool" = google_container_node_pool.this.name }
  description = "map(string) ||| Node selector labels that target nodes in this GPU node pool."
}

output "gpu_sharing_strategy" {
  value       = var.max_shared_clients_per_gpu > 1 ? "TIME_SHARING" : ""
  description = "string ||| The GPU sharing strategy in effect (\"TIME_SHARING\"), or empty string when GPUs are dedicated."
}

output "max_shared_clients_per_gpu" {
  value       = var.max_shared_clients_per_gpu
  description = "number ||| The number of pods that can share each physical GPU. 1 means dedicated GPUs."
}

output "accelerator_type" {
  value       = var.accelerator_type
  description = "string ||| The GPU accelerator type attached to each node in this pool."
}

output "accelerator_count" {
  value       = var.accelerator_count
  description = "number ||| The number of physical GPUs attached to each node in this pool."
}

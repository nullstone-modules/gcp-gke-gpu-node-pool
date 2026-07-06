variable "machine_type" {
  type        = string
  default     = "g4-standard-48"
  description = <<EOF
Node instance machine type. Must be a machine family with attached GPUs (e.g. G4).
The default "g4-standard-48" carries 1x NVIDIA RTX PRO 6000 (96GB VRAM).
See https://cloud.google.com/compute/docs/gpus.
EOF
}

variable "accelerator_type" {
  type        = string
  default     = "nvidia-rtx-pro-6000"
  description = "The GPU accelerator type attached to each node. Must match the machine type's GPU (e.g. \"nvidia-rtx-pro-6000\" for G4)."
}

variable "accelerator_count" {
  type        = number
  default     = 1
  description = "The number of GPUs attached to each node. Must match the machine type's GPU count."
}

variable "max_shared_clients_per_gpu" {
  type        = number
  default     = 3
  description = <<EOF
The number of pods that can share each physical GPU via GKE time-slicing.
Each node advertises `nvidia.com/gpu = accelerator_count * max_shared_clients_per_gpu` allocatable.
Set to 1 to disable time-slicing (each GPU is dedicated to a single pod).

NOTE: Time-slicing shares compute, not memory. The sum of VRAM fractions used by pods sharing a
GPU should stay at or below 0.90 (e.g. 3 vLLM models with `gpu_memory_utilization=0.30` each).
EOF

  validation {
    condition     = var.max_shared_clients_per_gpu >= 1
    error_message = "max_shared_clients_per_gpu must be at least 1."
  }
}

variable "gpu_driver_version" {
  type        = string
  default     = "LATEST"
  description = "The NVIDIA driver version that GKE auto-installs on the nodes. One of \"DEFAULT\", \"LATEST\", or \"INSTALLATION_DISABLED\"."

  validation {
    condition     = contains(["DEFAULT", "LATEST", "INSTALLATION_DISABLED"], var.gpu_driver_version)
    error_message = "gpu_driver_version must be one of \"DEFAULT\", \"LATEST\", or \"INSTALLATION_DISABLED\"."
  }
}

variable "num_node_zones" {
  type        = number
  default     = 2
  description = <<EOF
The number of zones to allocate GPU nodes.
Zones are pulled from the zones available in the cluster's region (GCP subnets are regional, so every zone in the region is reachable from the network).
This works in combination with min_node_count, max_node_count to determine how many nodes to create.
With min_node_count=1, max_node_count=3, num_node_zones=2, the node pool will provision at least 2 nodes and at most 6 nodes.
NOTE: GPU machine families are not available in every zone; check availability with
`gcloud compute accelerator-types list --filter="name=<accelerator_type>"`.
EOF
}

variable "min_node_count" {
  type        = number
  default     = 1
  description = "Minimum number of nodes per zone in the GPU node pool."
}

variable "max_node_count" {
  type        = number
  default     = 3
  description = "Maximum number of nodes per zone in the GPU node pool."
}

variable "spot" {
  type        = bool
  default     = false
  description = "Use spot VMs for GPU nodes. Significantly cheaper, but nodes can be preempted at any time."
}

variable "disk_type" {
  type        = string
  default     = "hyperdisk-balanced"
  description = "The disk type for each node's boot disk. G4 machines only support Hyperdisk (default \"hyperdisk-balanced\")."
}

variable "disk_size" {
  type        = number
  default     = 100
  description = "The boot disk size of each node in GB. This disk is used for OS files, logs, and images (large model images need headroom)."
}

# gcp-gke-gpu-node-pool

Nullstone module that adds a GPU node pool with time-slicing to an existing GKE cluster.

Designed for serving multiple GPU workloads (e.g. vLLM models) per physical GPU: with the
defaults, each `g4-standard-48` node (1x NVIDIA RTX PRO 6000, 96GB VRAM) advertises
`nvidia.com/gpu: 3` allocatable via GKE time-slicing, so 3 pods each requesting 1 GPU slot
schedule onto one node.

Pair with the `gcp-gke-gpu-cores` capability on a `gcp-gke-service` app to request GPU slots,
target this pool, and tolerate the GPU taint.

## Requirements

- The cluster must run **GKE 1.34+** (set `min_master_version = "1.34"` on the `gcp-gke` block).
  The apply fails with a precondition error otherwise.
- GKE automatically taints GPU nodes with `nvidia.com/gpu=present:NoSchedule`. System workloads
  (kube-dns, external-secrets) cannot schedule here — **the cluster must keep at least one
  untainted node pool**.
- G4 machines only support Hyperdisk boot disks (`disk_type` defaults to `hyperdisk-balanced`).
- GPU drivers are auto-installed by GKE (`gpu_driver_version`, default `LATEST`).

## Connections

- `cluster` — `cluster/gcp/k8s:gke`
  - The GKE cluster to attach the node pool to. Reuses the cluster's node service account when
    available (`gcp-gke` 0.7.0+).

## Inputs

- `num_node_zones: number` — default `2`
  - The number of zones to allocate GPU nodes. Zones are pulled from the zones available in the
    cluster's region. NOTE: GPU machine families are not available in every zone; check with
    `gcloud compute accelerator-types list --filter="name=<accelerator_type>"`.
- `machine_type: string` — default `g4-standard-48`
- `accelerator_type: string` — default `nvidia-rtx-pro-6000`
- `accelerator_count: number` — default `1`
- `max_shared_clients_per_gpu: number` — default `3`
  - Pods per physical GPU via time-slicing. Set `1` to dedicate GPUs.
- `gpu_driver_version: string` — default `LATEST`
- `min_node_count / max_node_count: number` — defaults `1` / `3` (per zone)
- `spot: bool` — default `false`
- `disk_type: string` — default `hyperdisk-balanced`
- `disk_size: number` — default `100`

## VRAM budgeting with time-slicing

Time-slicing shares GPU **compute**, not memory — every pod sees the full GPU and there is no
memory isolation. Budget VRAM explicitly: the sum of VRAM fractions of pods sharing a GPU should
stay **at or below 0.90**. For example, 3 vLLM models on one 96GB GPU each set
`--gpu-memory-utilization 0.30`.

## Outputs

- `node_pool_name: string` — the name of the GPU node pool.
- `node_selector: map(string)` — node selector labels targeting this pool
  (`cloud.google.com/gke-nodepool: <pool name>`).
- `gpu_sharing_strategy: string` — `TIME_SHARING`, or empty when dedicated.
- `max_shared_clients_per_gpu: number` — pods per physical GPU.
- `accelerator_type: string` — the GPU accelerator type.
- `accelerator_count: number` — physical GPUs per node.

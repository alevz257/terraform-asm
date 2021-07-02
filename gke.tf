variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

data "google_project" "project" {
  project_id = var.project_id
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-asm-demo"
  location = var.zone
  project  = var.project_id

  provider = google-beta

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  private_cluster_config {
    enable_private_endpoint = "false"
    enable_private_nodes = "true"
    master_ipv4_cidr_block = var.private_cidr
  }

  master_authorized_networks_config {
      cidr_blocks {
          cidr_block   = "0.0.0.0/0"
          display_name = "all-for-testing"
      }
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block = "10.1.0.0/20"
    services_ipv4_cidr_block = "10.2.0.0/23"
  }

  workload_identity_config {
    identity_namespace = "${var.project_id}.svc.id.goog"
  }

  resource_labels = {
    mesh_id = "proj-${data.google_project.project.number}"
  }

}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool-asm"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "n1-standard-4"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}


variable "project_id" {
  description = "project_id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "private_cidr" {
  description = "for gke master private cidr"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc-asm"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet-asm"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

resource "google_compute_firewall" "firewall" {
  name    = "allow-sidecar"
  network = google_compute_network.vpc.name

  allow {
    protocol  = "tcp"
    ports     = ["443","15017"]
  }

  source_ranges = [var.private_cidr]
}

#router
resource "google_compute_router" "router" {
  name    = "nat-router-asm"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

#NAT
resource "google_compute_router_nat" "nat" {
  name                               = "demo-router-nat-asm"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

}

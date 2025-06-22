terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_container_cluster" "primary" {
  name     = "desarrollo"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "default"
  subnetwork = "default"
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = var.zone

  node_count = 2

  node_config {
    machine_type = "e2-standard-4"
    tags = ["allow-api"]
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_compute_firewall" "allow_observability_ports" {
  name    = "allow-observability-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [
      "3000",   # Grafana
      "20001",  # Kiali
      "9090",   # Prometheus
      "80",     # Tracing (Jaeger)
      "9411",   # Zipkin
      "16685",  # Jaeger gRPC
      "14268", "14250",  # Jaeger collector ports
      "15443", "15021", "31400"
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-api"]
}


## A private GKE cluster, Control plane reachable via public endpoint

resource "google_container_cluster" "inventory_cluster" {
  name     = "inventory-cluster"
  location = var.zone

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.private_subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1 

  deletion_protection = false

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  cluster_autoscaling {
    enabled = false
  }

  release_channel {
    channel = "REGULAR"
  }
}
## Creating Compute Engine VMs, Autoscaling, Node service accounts, 
# logging+monitoring, node upgrade and repairs

resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-nodes"
  cluster  = google_container_cluster.inventory_cluster.name
  location = var.zone

  #initial_node_count — only applied at creation, autoscaler owns it after
  initial_node_count = 2

  node_config {
    machine_type    = "e2-standard-4"
    disk_size_gb = 50
    disk_type    = "pd-standard"
    service_account = google_service_account.gke_nodes.email

    #Required for Workload Identity to work at pod level
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      env = "prod"
    }
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 6
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}


# Allows GKE master to reach nodes
resource "google_compute_firewall" "allow_gke_master" {
  name    = "allow-gke-master"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["10250", "443"]
  }

  # Must match your master_ipv4_cidr_block in gke.tf
  source_ranges = ["172.16.0.0/28"]
}
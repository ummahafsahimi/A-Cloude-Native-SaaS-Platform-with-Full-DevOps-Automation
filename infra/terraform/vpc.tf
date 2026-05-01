# Creating a custom VPC
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

#Subnets (1 public for Load Banancers+NAT , 1 private for GKE nodes + MemoryStore Redis)
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true
  #lets private resources reach Google APIs without public IPs
 #Add secondary ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

## This is the standard GCP pattern for private clusters and MemoryStore.
#Cloud Router, required for NAT
resource "google_compute_router" "router" {
  name    = "inventory-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

#CLoud NAT, lets private GKE nodes pull images, reach Google APIs, etc
resource "google_compute_router_nat" "nat" {
  name                               = "inventory-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

## Allow health checks from Google Load Balancers. Why these two?
#allow-internal → lets private subnet resources communicate
#allow-lb-health-checks → required for GKE Ingress to function
#No public SSH, no open ports — secure by default
#This is exactly what a production GCP cluster uses.

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.id

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.0.0/16"]
}

resource "google_compute_firewall" "allow_lb_health_checks" {
  name    = "allow-lb-health-checks"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
}


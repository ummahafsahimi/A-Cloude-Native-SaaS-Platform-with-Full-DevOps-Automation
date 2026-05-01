#Creates a managed Redis instance, High availability, 1GB memory, Private IP only, 
#Attached to my vpc, so GKE can reach it privately

resource "google_redis_instance" "inventory_redis" {
  name               = "inventory-redis"
  tier               = "STANDARD_HA"
  memory_size_gb     = 1
  region             = var.region
  authorized_network = google_compute_network.vpc.id
}

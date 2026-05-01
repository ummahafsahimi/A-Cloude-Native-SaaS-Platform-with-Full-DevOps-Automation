## Creates a Docker repository in my chosen region
resource "google_artifact_registry_repository" "inventory_repo" {
  provider = google
  location = var.region
  repository_id = "inventory-registry"
  description   = "Docker images for the inventory platform"
  format        = "DOCKER"
}

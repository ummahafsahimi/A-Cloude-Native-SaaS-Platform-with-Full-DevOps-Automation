## Reference VPC+subnets when creating GKE, 
# MemoryStore Redis, and other resources
output "vpc_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = google_compute_subnetwork.public_subnet.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = google_compute_subnetwork.private_subnet.id
}

output "artifact_registry_repo" {
  description = "Artifact Registry repository URL"
  value       = google_artifact_registry_repository.inventory_repo.id
  # This helps when configuring CI/CD later.
}

output "redis_host" {
  description = "Redis endpoint"
  value       = google_redis_instance.inventory_redis.host
  # This will be used later in your Kubernetes manifests as an environment variable.
}

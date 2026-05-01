## GSA used by the GKE node pool
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes-sa"
  display_name = "GKE Nodes Service Account"
}

## GSA used by GitHub Actions for CI/CD
resource "google_service_account" "cicd" {
  account_id   = "cicd-sa"
  display_name = "CI/CD Service Account"
}

## GSA used by workloads that connect to Memorystore Redis
resource "google_service_account" "redis_client" {
  account_id   = "redis-client-sa"
  display_name = "Redis Client Service Account"
}

## Allow GKE nodes to write logs
resource "google_project_iam_member" "gke_nodes_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

## Allow GKE nodes to write metrics
resource "google_project_iam_member" "gke_nodes_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

## Allow GKE nodes to pull images from Artifact Registry
resource "google_project_iam_member" "gke_nodes_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

## Allow CI/CD to push images to Artifact Registry
resource "google_project_iam_member" "cicd_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cicd.email}"
}

## Allow CI/CD to authenticate via Workload Identity Federation
resource "google_project_iam_member" "cicd_workload_identity" {
  project = var.project_id
  role    = "roles/iam.workloadIdentityUser"
  member  = "serviceAccount:${google_service_account.cicd.email}"
}

## Allow Redis client workloads to access Memorystore Redis
resource "google_project_iam_member" "redis_client_role" {
  project = var.project_id
  role    = "roles/redis.editor"
  member  = "serviceAccount:${google_service_account.redis_client.email}"
}

## GSA for all API microservices
resource "google_service_account" "svc_api" {
  account_id   = "svc-api-sa"
  display_name = "API microservices GSA"
}

## GSA for cartservice (Redis client)
resource "google_service_account" "svc_cartservice" {
  account_id   = "svc-cartservice-sa"
  display_name = "Cartservice GSA"
}

## GSA for worker services (emailservice, loadgenerator)
resource "google_service_account" "svc_worker" {
  account_id   = "svc-worker-sa"
  display_name = "Worker microservices GSA"
}

## Allow API KSA to impersonate API GSA
resource "google_service_account_iam_member" "api_wi" {
  service_account_id = google_service_account.svc_api.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/svc-api]"
}

## Allow cartservice KSA to impersonate cartservice GSA
resource "google_service_account_iam_member" "cartservice_wi" {
  service_account_id = google_service_account.svc_cartservice.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/svc-cartservice]"
}

## Allow worker KSA to impersonate worker GSA
resource "google_service_account_iam_member" "worker_wi" {
  service_account_id = google_service_account.svc_worker.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/svc-worker]"
}

## Allow API GSA to read images from Artifact Registry
resource "google_project_iam_member" "api_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.svc_api.email}"
}

## Allow API GSA to write logs
resource "google_project_iam_member" "api_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.svc_api.email}"
}

## Allow API GSA to write metrics
resource "google_project_iam_member" "api_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.svc_api.email}"
}

## Allow cartservice GSA to access Memorystore Redis
resource "google_project_iam_member" "cartservice_redis" {
  project = var.project_id
  role    = "roles/redis.editor"
  member  = "serviceAccount:${google_service_account.svc_cartservice.email}"
}

## Allow worker GSA to read images from Artifact Registry
resource "google_project_iam_member" "worker_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.svc_worker.email}"
}

 # required by GKE's metrics collection agent
resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
# required for resource metadata (pod/node labels in Cloud Monitoring)
resource "google_project_iam_member" "gke_nodes_resource_metadata" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
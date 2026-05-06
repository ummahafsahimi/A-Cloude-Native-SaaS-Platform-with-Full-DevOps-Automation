# Online Boutique — Cloud Native Microservices on GCP

A production-grade deployment of a cloud-native online boutique shop built with 10 microservices, fully automated CI/CD pipeline, and GitOps-based delivery on Google Cloud Platform.

---

## Architecture Overview

```
Developer pushes code
        ↓
GitHub Actions (CI)
  - Detects changed microservice
  - Authenticates to GCP via Workload Identity Federation
  - Builds & pushes Docker image to Artifact Registry
  - Updates appVersion in GitOps repo
        ↓
ArgoCD (CD)
  - Watches GitOps repo (gitOps branch)
  - Auto-syncs changes to GKE cluster via Helm
        ↓
GKE Cluster (northamerica-northeast2)
  - 10 microservices running in ms-app namespace
  - Memorystore Redis for cart storage
  - LoadBalancer for public access
```

---

## Infrastructure Stack

| Component | Technology |
|---|---|
| Cloud Provider | Google Cloud Platform (GCP) |
| Container Orchestration | Google Kubernetes Engine (GKE) |
| Infrastructure as Code | Terraform |
| Container Registry | Google Artifact Registry |
| Cache / Session Store | Google Memorystore (Redis) |
| CI Pipeline | GitHub Actions |
| CD Pipeline | ArgoCD |
| Package Manager | Helm |
| Identity & Auth | Workload Identity Federation (WIF) |
| Networking | VPC, Cloud NAT, Cloud Router |

---

## Microservices

| Service | Language | Description |
|---|---|---|
| frontend | Go | Serves the web UI, routes to all backend services |
| cartservice | C# | Manages shopping cart, backed by Redis |
| productcatalogservice | Go | Returns list of products |
| currencyservice | Node.js | Converts currency |
| paymentservice | Node.js | Processes payments |
| shippingservice | Go | Calculates shipping cost |
| emailservice | Python | Sends order confirmation emails |
| checkoutservice | Go | Orchestrates checkout flow |
| recommendationservice | Python | Recommends products |
| adservice | Java | Serves contextual ads |

---

## GCP Infrastructure (Terraform)

### Networking (`vpc.tf`)
- Custom VPC with public and private subnets
- Cloud Router + Cloud NAT for private node egress
- Firewall rules for internal traffic, LB health checks, and GKE master → node communication (`172.16.0.0/28:10250`)

### GKE Cluster (`gke.tf`)
- Zonal private cluster (`northamerica-northeast2-a`)
- Private nodes with public control plane endpoint
- Workload Identity enabled
- Node pool: `e2-standard-4`, autoscaling 2–6 nodes

### IAM (`iam.tf`)
- Dedicated service accounts per workload (least privilege)
- Node SA with logging, monitoring, and Artifact Registry roles
- CI/CD SA with Artifact Registry writer role
- Workload Identity bindings for pod-level GCP access

---

## CI/CD Pipeline

### CI — GitHub Actions (`.github/workflows/ci.yaml`)

Triggers on:
- Push to `main` with changes under `src/`
- Manual `workflow_dispatch` (supports single service or `all`)

Steps:
1. Detect changed microservice(s) from git diff
2. Authenticate to GCP via Workload Identity Federation — no long-lived keys
3. Build Docker image
4. Push to Artifact Registry
5. Clone GitOps repo and update `appVersion` with commit SHA
6. Commit and push to `gitOps` branch

### CD — ArgoCD
- Watches `gitOps` branch of GitOps repo
- One ArgoCD `Application` per microservice
- Automated sync with `prune` and `selfHeal` enabled
- Deploys via Helm using per-service values files

---

## Repository Structure

```
google-microservices-demo/          ← source repo
├── src/
│   ├── frontend/
│   ├── cartservice/
│   ├── checkoutservice/
│   └── ...                         ← 10 microservices
└── .github/workflows/ci.yaml       ← CI pipeline

A-Cloude-Native-SaaS-Platform/      ← GitOps repo (gitOps branch)
├── charts/
│   └── microservice/               ← shared Helm chart
├── values/
│   ├── frontend-values.yaml
│   ├── cart-service-values.yaml
│   └── ...                         ← per-service values
└── argocd-app.yaml                 ← ArgoCD Application manifests
```

---

## Key Engineering Decisions

**Workload Identity Federation over service account keys**
No long-lived credentials stored in GitHub. GitHub Actions authenticates to GCP by exchanging a short-lived OIDC token, scoped to a specific repository.

**Zonal over regional cluster**
Chose a zonal cluster to stay within GCP free tier SSD quota (500GB). Regional clusters multiply nodes across 3 zones, hitting quota limits silently.

**One ArgoCD Application per microservice**
Avoids Helmfile dependency, uses ArgoCD's native Helm support. Each service syncs independently — a bad deploy to one service doesn't block others.

**GitOps separation of source and config**
Application code lives in the source repo. Deployment config (image tags, replicas, env vars) lives in a separate GitOps repo. ArgoCD only watches the GitOps repo — clean separation of concerns.

---

## Lessons Learned

- GKE node pool `ERROR` after 25 minutes = check `gcloud container operations describe`, not Terraform output
- Regional clusters silently multiply node count — always verify with `gcloud compute instances list`
- WIF `unauthorized_client` = attribute condition mismatch on the provider, not IAM — check provider first
- `gcloud auth configure-docker` is unreliable in WIF workflows — use `docker/login-action` with `token_format: access_token`
- ArgoCD `sourceType: Directory` means it's reading raw files, not Helm — explicitly configure `helm.valueFiles`

---

## Getting Started

### Prerequisites
- GCP project with billing enabled
- Terraform >= 1.0
- `gcloud` CLI authenticated
- `kubectl` configured
- ArgoCD installed on cluster

### Deploy Infrastructure
```bash
cd terraform/
terraform init
terraform apply
```

### Configure kubectl
```bash
gcloud container clusters get-credentials inventory-cluster \
  --zone=northamerica-northeast2-a \
  --project=YOUR_PROJECT_ID
```

### Deploy All Services (first time)
Trigger the CI pipeline manually:
```
GitHub → Actions → Build, Push & Update GitOps → Run workflow → type "all" → Run
```

ArgoCD will automatically sync and deploy all services once the GitOps repo is updated.

### Access the App
```bash
kubectl get svc frontend -n ms-app
# use the EXTERNAL-IP in your browser
```

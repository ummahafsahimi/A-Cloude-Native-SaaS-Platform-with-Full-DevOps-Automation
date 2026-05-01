# Cloud‑Native Microservices Platform on GKE
End‑to‑End DevOps Project with Terraform, GKE, Redis, Helmfile & CI/CD Foundation

This project is a production‑grade microservices platform deployed on Google Kubernetes Engine (GKE) using Terraform, Helmfile, and CI/CD (future step).
It demonstrates real DevOps skills across infrastructure provisioning, container orchestration, service deployment, observability, and cloud‑native architecture.

It is designed as a real business scenario: a scalable e‑commerce application that can handle traffic spikes, support rapid deployments, and maintain high availability.

## Architecture Overview
### Infrastructure (Terraform)
Provisioned using Terraform:

GKE Autopilot Cluster

Memorystore Redis Instance

VPC + Subnets

Firewall rules

Service Accounts & IAM

Artifact Registry 

### Application Layer (Helmfile + Helm Charts)
11 microservices deployed via a single Helmfile

Shared microservice Helm chart for consistent deployment patterns

Environment‑specific values files

LoadBalancer service for frontend exposure

Redis connection for cart service

Automatic namespace creation

### Networking
Internal service‑to‑service communication via ClusterIP

External access via GKE LoadBalancer

Redis private IP connectivity

### CI/CD (Planned)
Jenkins pipeline

Workload Identity Federation (no secrets)

Build → Push → Deploy workflow

Terraform validation + plan

Helmfile apply on merge


## How to Deploy
### 1. Provision Infrastructure
Code

cd infra/terraform

terraform init

terraform apply
### 2. Connect to GKE
Code

gcloud container clusters get-credentials <cluster-name> --region <region>
### 3. Deploy Microservices
Code

helmfile apply
### 4. Access the Application
Code

kubectl get svc -n ms-app

Now Open the frontend LoadBalancer IP

## Live Application
Once deployed, the UI is available at:


http://YOUR-loadbalancer-IP

This OnlineBoutique shop will appear...

<img width="941" height="459" alt="image" src="https://github.com/user-attachments/assets/cf03f14e-960c-42cf-a188-2a5b7ec92186" />


## Debugging & Troubleshooting 
Here I have solved real production‑style issues:

Fixed multiple ImagePullBackOff errors by tracing wrong image tags and mismatched chart values.

Solved frontend crash loops by identifying missing env vars through pod logs (SHOPPING_ASSISTANT_SERVICE_ADDR).

Cleaned broken deployments by destroying Helm releases and removing stuck namespaces safely.

Debugged service‑to‑service failures using kubectl describe, events, and ClusterIP validation.

Recovered from Helmfile plugin issues and corrected chart rendering problems.

Validated Redis connectivity and fixed cart service configuration using private IP settings.

Exposed the frontend correctly by switching service type to LoadBalancer and verifying external access.

Hit a Terraform Workload Identity binding race and fixed it by enforcing correct dependency ordering on the GKE cluster.

Ran into GKE SSD quota/limit issues and resolved them by adjusting node pool configuration and understanding GCP resource limits.

# Future Enhancements
Add Jenkins CI/CD

Add HTTPS + domain via GKE Ingress

Add Cloud Monitoring dashboards

Add autoscaling (HPA)

Add distributed tracing

Add service mesh (Istio or Anthos)

# platform-terraform

Shared Terraform modules for self-service infrastructure provisioning with organizational guardrails.

Part of the [Ford Platform Adoption Strategy](../platform-workflows/docs/strategy/platform-adoption-strategy.md) — Pillar 2 (Infrastructure as Code).

## Why This Exists

80+ teams provisioning infrastructure independently = cost incidents, unlabeled resources, security violations, and 45-minute MTTR finding who owns a service at 2 AM. This repo encodes every organizational lesson into reusable modules so **teams get production-grade infrastructure with 7 lines of config**.

See [docs/iac-platform-strategy.md](docs/iac-platform-strategy.md) for the full strategy.

## Structure

```
modules/
  cloud-run-service/     # Cloud Run v2 with org guardrails
environments/
  dev/                   # Dev environment (auto-deploy on merge)
  staging/               # Staging (deploy on tag) — Day 9
  prod/                  # Production (manual approval) — Day 9
docs/
  iac-platform-strategy.md  # Pillar 2 strategy document
```

## Quick Start (Developer Self-Service)

Add your service to the appropriate environment config:

```hcl
module "my_service" {
  source       = "../../modules/cloud-run-service"
  project_id   = var.project_id
  service_name = "customer-api"
  image        = "us-central1-docker.pkg.dev/myproj/images/customer-api:v2.1"
  environment  = "dev"
  team         = "marketing-web"
  cost_center  = "MKT-40210"
}
```

That's it. The module handles: scaling limits, security posture, networking, labels, health checks, IAM.

Open a PR → plan runs → review → merge → deployed.

## Module: cloud-run-service

Deploys a Cloud Run v2 service with enforced organizational standards.

### Required Inputs

| Name | Description |
|------|-------------|
| `project_id` | GCP project ID |
| `service_name` | Cloud Run service name (validated: lowercase, 3-63 chars) |
| `image` | Container image (validated: must be from Artifact Registry) |
| `environment` | `dev`, `staging`, or `prod` |
| `team` | Owning team name (used for labeling + incident routing) |
| `cost_center` | Finance cost center code (validated: XX-NNNNN format) |

### Optional Inputs (Sensible Defaults)

| Name | Default | Why This Default |
|------|---------|-----------------|
| `region` | `us-central1` | Org-approved region (validated list) |
| `cpu` / `memory` | `1` / `512Mi` | Standardized tiers (validated) |
| `min_instances` | `0` | Scale-to-zero in non-prod saves cost |
| `max_instances` | `10` | Cost ceiling (validated: max 50, load test for more) |
| `port` | `8080` | Standard container port |
| `concurrency` | `80` | Right-sized for most APIs |
| `allow_unauthenticated` | `false` | Secure by default |
| `ingress` | `INTERNAL_ONLY` | Private by default |
| `secrets` | `{}` | Secret Manager references (not env vars) |
| `vpc_connector` | `""` | VPC connector for private networking |

### Enforced Labels (Cannot Override)

| Label | Source | Purpose |
|-------|--------|---------|
| `managed-by` | `terraform` | Ops: "Was this IaC-created?" |
| `team` | `var.team` | Incidents: "Who do I page?" |
| `cost-center` | `var.cost_center` | Finance: "Who pays?" |
| `environment` | `var.environment` | Safety: "Is this prod?" |

## Setup

1. Create GCS bucket for state: `gsutil mb gs://YOUR-TFSTATE-BUCKET`
2. Update `environments/dev/backend.tf` with your bucket name
3. Update `environments/dev/terraform.tfvars` with your project ID
4. Run: `cd environments/dev && terraform init && terraform plan`

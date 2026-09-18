# Pillar 2: Infrastructure as Code — The Self-Service Guardrail Strategy

**Extends:** [Ford Platform Adoption & Migration Strategy](../../platform-workflows/docs/strategy/platform-adoption-strategy.md)  
**Version:** 1.0 | **Date:** September 2026 | **Classification:** Internal — Platform Team  
**Focus:** How shared Terraform modules become the organizational memory that makes self-service possible

---

## 1. The Ground Reality: Why This Is Hard

You're the Platform Architect. You've been in the trenches — migrating 130+ Terraform
workspaces from TFE to Atlantis, debugging provider binaries that arrived as XML error
responses at 2 AM, fixing firewall rules that silently didn't apply because nobody knew
GKE nodes in Shared VPC need explicit target tags, discovering that the "simple"
namespace rename would break ArgoCD sync.

You know the pain. You've lived it.

Now leadership says: **"Enable 80+ teams to self-service their infrastructure."**

And you think: *"How? Every time I give a team access to Terraform, one of three things
happens:"*

1. **They create something dangerous.** Uncapped scaling. Public endpoints. Hardcoded
   secrets. No labels. Console-created resources with no state. You find out about it
   during an incident — at 2 AM, or when Finance asks who owns the $14K Cloud Run bill.

2. **They create something fragile.** Copy-paste from Stack Overflow. Wrong provider
   versions. No backend config. State in local files. When it breaks, they open a
   ticket to the platform team — "Terraform is broken." No, your Terraform is broken.

3. **They don't create anything at all.** The barrier is too high. They open a Jira
   ticket asking the platform team to provision infrastructure for them. 2-week lead
   time. You become a ticket queue. Your team burns out. The developers hate waiting.

**All three outcomes are the same failure:** the organization's hard-won knowledge
isn't reaching the teams that need it.

The developer who just joined the Marketing team doesn't know about the $14K
incident. Doesn't know about the supply chain policy violation from DockerHub images.
Doesn't know that Cloud Run services without labels are invisible to Finance.
Doesn't know the approved regions, the naming conventions, the security posture.

They shouldn't HAVE to know. **That's the platform's job.**

---

## 2. The Vision: Modules as Organizational Memory

The platform adoption strategy (Section 3) defines the Agent-First IDP architecture.
This document focuses on what sits underneath the agent — the Terraform modules that
encode every lesson the organization has learned into defaults, validations, and
constraints.

### 2.1 What "Self-Service" Looks Like in Practice

The developer's entire experience:

```hcl
# This is the ONLY file a developer writes to deploy a production-grade service.
# Everything else — scaling limits, security posture, networking, labels,
# health checks, IAM — is handled by the module.

module "customer_api" {
  source       = "git::https://github.com/ford-org/platform-terraform//modules/cloud-run-service"
  project_id   = var.project_id
  service_name = "customer-api"
  image        = "us-central1-docker.pkg.dev/ford-mkt-dev/images/customer-api:v2.1"
  environment  = "dev"
  team         = "marketing-web"
  cost_center  = "MKT-40210"
}
```

**Seven lines.** That's it.

What they get automatically (without knowing, asking, or configuring):

| What the Module Does | Why | What It Prevents |
|---|---|---|
| Sets `max_instances = 10` | Cost ceiling | The $14K weekend bill |
| Sets `ingress = INTERNAL_ONLY` | Zero trust | Accidental internet exposure |
| Sets `allow_unauthenticated = false` | Secure by default | allUsers on production services |
| Adds `managed-by=terraform` label | Ops traceability | "Was this created in Console?" at 2 AM |
| Adds `team=marketing-web` label | Ownership | "Who do I page?" during incidents |
| Adds `cost-center=MKT-40210` label | FinOps | "Who pays for this?" — every quarter |
| Adds startup probe on `/healthz` | Reliability | Ghost instances serving 503s |
| Validates image from `*.pkg.dev` only | Supply chain | DockerHub images in production |
| Validates region against approved list | Data residency | Resources in non-compliant regions |
| Validates cost center format | Finance integration | Unlabeled resources in billing |
| Validates CPU/memory to standard tiers | Cost predictability | Over-provisioned 32Gi containers |

**The developer didn't read a doc. Didn't attend a training. Didn't know these
rules existed.** They just used the module — and the module remembered for them.

### 2.2 The Three-Layer Guardrail Architecture

Following the main strategy's enforcement spectrum (Section 3.3), the Terraform layer
implements:

```
Layer 1: MODULE DEFAULTS (Transparent — developer never sees these)
│  ├── Secure-by-default configurations
│  ├── Right-sized resource allocations
│  ├── Private networking posture
│  ├── Health check probes
│  └── Enforced labels (team, cost-center, environment, managed-by)
│
Layer 2: VALIDATION BLOCKS (Soft Block — developer sees clear error + guidance)
│  ├── Image source must be Artifact Registry (not DockerHub)
│  ├── Region must be org-approved list
│  ├── max_instances capped with cost-incident backstory
│  ├── CPU/memory in standardized tiers
│  ├── Cost center format validation
│  └── Service name format validation
│
Layer 3: PLAN-TIME REVIEW (Human in the Loop)
│  ├── terraform plan posted as PR comment (Day 7)
│  ├── Platform team reviews resource changes
│  ├── Environment protection rules for staging/prod
│  └── Agent validates against Ford standards pre-merge
│
Layer 4: POLICY ENGINE (Future — OPA/Sentinel)
   ├── Cross-module constraints (total cost per team)
   ├── Drift detection and auto-remediation
   ├── Compliance reporting for SOX/GDPR
   └── Binary Authorization for container images (Day 5)
```

**Key principle from the main strategy:** "The agent doesn't replace the guardrails —
it accelerates the golden path." The Terraform module IS the guardrail. The agent,
the CI pipeline, and the human developer all go through the same module. Same
validations. Same defaults. Same enforced labels. There is no backdoor.

---

## 3. How the Module Encodes Real Incidents

Every `validation` block in the module is a scar from a real incident. This is the
"organizational memory" — lessons that would otherwise exist only in a senior
engineer's head, lost when they leave the company.

### 3.1 The Cost Incident → max_instances Validation

```
Incident:  A team set max_instances = 1000 "just to be safe."
           Traffic spike. Cloud Run scaled to 200 instances.
           Weekend bill: $14,000.
           Nobody noticed until Monday.

Lesson:    Scale limits must have a ceiling.
           Teams requesting higher limits need a load test review.

Encoded:   validation {
             condition     = var.max_instances <= 50
             error_message = "max_instances must be 1-50. Need >50?
                             Platform team reviews the load test first."
           }

Result:    Zero cost incidents from scaling since implementation.
```

### 3.2 The Supply Chain Violation → Image Source Validation

```
Incident:  A team pulled a container from DockerHub for production.
           No scan. No signature. No SBOM.
           Security audit flagged it. 2 weeks of remediation paperwork.
           Now multiply that by 80 teams.

Lesson:    All production images must come from Artifact Registry
           where Day 5's container-build workflow already scans,
           signs (cosign), and generates SBOM.

Encoded:   validation {
             condition     = can(regex("^[a-z0-9.-]+\\.pkg\\.dev/", var.image))
             error_message = "Images must come from Artifact Registry.
                             DockerHub and public registries are blocked."
           }

Result:    100% of images in IaC-managed services are scanned + signed.
```

### 3.3 The 2 AM Incident → Enforced Labels

```
Incident:  PagerDuty alert for a Cloud Run service throwing 500s.
           On-call engineer checks GCP Console. Service name: "api-server."
           No labels. No team. No cost center.
           45 minutes to find the owning team. 5-minute fix.
           MTTR inflated 9x because of missing metadata.

Lesson:    Every resource must have team, cost-center, environment,
           and managed-by labels. Not optional. Not "best practice."
           Non-negotiable.

Encoded:   locals {
             enforced_labels = {
               team        = var.team
               cost-center = var.cost_center
               environment = var.environment
               managed-by  = "terraform"
             }
           }
           These merge AFTER extra_labels — cannot be overridden.

Result:    Every IaC-managed service is immediately traceable:
           who owns it, who pays, what environment, how it was created.
```

### 3.4 The Data Residency Issue → Region Validation

```
Incident:  A team deployed to asia-southeast1 for "lower latency."
           Compliance discovered customer data processing outside
           approved regions. Regulatory remediation.

Lesson:    Region list is a compliance boundary, not a convenience.
           Adding new regions requires approval (legal, security, compliance).

Encoded:   validation {
             condition = contains(["us-central1", "us-east4",
                                   "europe-west1", "asia-south1"], var.region)
             error_message = "Region must be org-approved.
                             Contact platform team to add new regions."
           }

Result:    Developers can't accidentally create resources in
           non-compliant regions. Region expansion is intentional.
```

---

## 4. The Self-Service Flow: Developer Journey

### 4.1 New Service (< 10 minutes)

```
Step 1: Developer creates a branch in platform-terraform
        git checkout -b add-customer-api

Step 2: Copies an existing module block, changes 4 required fields
        (service_name, image, team, cost_center)

Step 3: Pushes and opens a PR
        git push → opens PR via gh CLI or GitHub UI

Step 4: GHA runs terraform plan (Day 7 workflow)
        Plan output posted as PR comment:
        "Plan: 3 to add, 0 to change, 0 to destroy"
        Developer sees EXACTLY what will be created

Step 5: Platform team reviews (or auto-approve for dev)
        Review scope is minimal — module handles defaults

Step 6: Merge → terraform apply runs automatically
        Service is live. Labels correct. Scaling safe.

Time: 10 minutes of developer work + review cycle
```

### 4.2 Same Flow via Agent (< 2 minutes)

```
Developer: "Deploy a new service called customer-api for marketing-web team"

Agent:      I'll create that using the Cloud Run module. Let me:
            1. ✓ Created branch: add-customer-api
            2. ✓ Generated Terraform config (7 lines)
            3. ✓ Opened PR #42 — plan shows 3 resources
            4. ✓ Plan passed all validations

            Review PR #42 and merge when ready.
            Dev environment will deploy automatically on merge.

Developer: "Merge it"

Agent:      ✓ Merged PR #42
            ✓ Apply succeeded: 3 resources created
            ✓ Service URL: https://customer-api-xyz.run.app (internal)

            The service is live with:
            - Scale: 0-10 instances (cost ceiling)
            - Ingress: internal only
            - Labels: team=marketing-web, cost-center=MKT-40210
```

**Both paths go through the same module.** Same validations. Same defaults. Same
guardrails. The agent doesn't bypass anything — it accelerates the golden path.

### 4.3 What Happens When Guardrails Trigger

```
Developer tries: max_instances = 200

terraform plan output:
│ Error: Invalid value for variable "max_instances"
│
│ max_instances must be 1-50. The $14K incident taught us this.
│ Need >50? Platform team reviews the load test first.

Developer understands:
- There's a limit (50)
- There's a reason (cost incident)
- There's a path forward (load test + platform team review)
- They are NOT blocked — they are GUIDED
```

```
Developer tries: image = "docker.io/myapp:latest"

terraform plan output:
│ Error: Invalid value for variable "image"
│
│ Images must come from Artifact Registry (*.pkg.dev).
│ DockerHub and other public registries are blocked by org policy.

Developer understands:
- There's a policy (AR only)
- There's a reason (supply chain security)
- The CI/CD pipeline (Day 5) already pushes to AR — just use that image path
```

**This is the critical design:** the error message is the guardrail. It doesn't say
"invalid value." It says WHY the constraint exists and WHAT to do next. A developer
who hits a guardrail should feel guided, not blocked.

---

## 5. How This Connects to the 3-Pillar Platform

From the main strategy (Section 3.1 Architecture):

```
PILLAR 1 (CI/CD)                  PILLAR 2 (IaC)                   PILLAR 3 (Agent)
Days 1-5                          Days 6-9                          Days 10-15
┌────────────────────┐            ┌────────────────────┐            ┌────────────────────┐
│ platform-workflows │            │ platform-terraform │            │ platform-agent     │
│                    │            │                    │            │                    │
│ container-build:   │───image───→│ cloud-run-service: │←──creates──│ provision_infra(): │
│  Build container   │   path     │  Deploy service    │   config   │  Natural language  │
│  Scan (Trivy)      │            │  Scale limits      │            │  → Terraform PR    │
│  Sign (cosign)     │            │  Org labels        │            │                    │
│  SBOM + provenance │            │  IAM bindings      │            │ deploy():          │
│  Push to AR        │            │  Health probes     │            │  Trigger apply     │
│                    │            │  Networking        │            │  Report status     │
│ deploy-cloudrun:   │            │                    │            │                    │
│  Deploy to env     │←──uses─────│  Environment configs│           │ explain_failure(): │
│  OIDC auth         │  module    │  dev/staging/prod  │            │  Read plan output  │
│                    │  outputs   │                    │            │  Explain errors    │
└────────────────────┘            └────────────────────┘            └────────────────────┘
         │                                 │                                 │
         │              TRUST CHAIN        │                                 │
         │     ┌───────────────────────────┐│                                │
         └────→│ Binary Authorization      │←────────────────────────────────┘
               │ Only signed images deploy │
               │ Only AR-sourced images    │  Agent can't bypass this.
               │ Only approved regions     │  CI can't bypass this.
               │ Module validation blocks  │  Human can't bypass this.
               └───────────────────────────┘
```

**The trust chain is unbroken:**
- Pillar 1 builds, scans, signs the image → pushes to Artifact Registry
- Pillar 2 validates that only AR images can be deployed → enforces org standards
- Pillar 3 orchestrates both → but goes through the same validation gates

No matter who triggers the deployment — a developer writing HCL, a CI pipeline on
merge, or an AI agent responding to "deploy my service" — the guardrails fire.

---

## 6. Module Catalog: What We Build and When

### Phase 1: Core Modules (Days 6-9 POC)

| Module | Purpose | Key Guardrails |
|---|---|---|
| `cloud-run-service` | Deploy containerized services | Scale ceiling, AR-only images, enforced labels, approved regions |
| `gcs-bucket` | Object storage | Uniform bucket-level access, versioning default on, public access prevention |
| `cloud-sql` | Managed PostgreSQL/MySQL | Private IP only, automated backups, deletion protection |

### Phase 2: Extended Modules (Post-POC)

| Module | Purpose | Key Guardrails |
|---|---|---|
| `gke-workload` | K8s deployment on shared GKE | Resource quotas, network policies, pod security standards |
| `pubsub-topic` | Event-driven messaging | Dead letter queue required, message retention policy |
| `cloud-function` | Serverless functions | VPC connector required for prod, same AR-only validation |
| `bigquery-dataset` | Analytics tables | Location constraint, access controls, expiration policies |
| `secret-manager` | Secrets storage | Rotation policy, IAM audit logging |

### Phase 3: Composition Modules (Platform Maturity)

| Module | Purpose | Combines |
|---|---|---|
| `web-service` | Complete web application stack | Cloud Run + GCS (static) + Cloud CDN + SSL |
| `data-pipeline` | ETL/ELT pipeline | Cloud Function + Pub/Sub + BigQuery + GCS |
| `api-service` | Internal API with DB | Cloud Run + Cloud SQL + Secret Manager |

**Key insight:** Composition modules are how the agent scales. Instead of the agent
generating 50 lines of Terraform for a complete service stack, it calls one
composition module with 6 inputs. Same guardrails. Same defaults. But the AI agent
needs to understand fewer parameters — reducing hallucination risk.

---

## 7. Environment Strategy: Same Module, Different Dials

```
environments/
├── dev/
│   ├── main.tf          # Module calls with dev-appropriate settings
│   ├── backend.tf       # GCS bucket: ford-poc-tfstate/dev
│   └── terraform.tfvars # project_id = "ford-mkt-dev"
├── staging/
│   ├── main.tf          # Same modules, staging settings
│   ├── backend.tf       # GCS bucket: ford-poc-tfstate/staging
│   └── terraform.tfvars # project_id = "ford-mkt-stg"
└── prod/
    ├── main.tf          # Same modules, prod settings
    ├── backend.tf       # GCS bucket: ford-poc-tfstate/prod
    └── terraform.tfvars # project_id = "ford-mkt-prd"
```

### Environment Defaults (Module User Sets These Per Env)

| Setting | Dev | Staging | Prod |
|---|---|---|---|
| `min_instances` | 0 (scale to zero) | 1 | 2+ |
| `max_instances` | 3 | 5 | 10-50 (load tested) |
| `allow_unauthenticated` | Allowed for testing | false | false |
| `ingress` | ALL (for testing) | INTERNAL_ONLY | INTERNAL_LOAD_BALANCER |
| `service_account` | Default compute SA | Dedicated SA | Dedicated SA + WIF |
| GHA deployment | Auto on merge | Auto on tag | Manual approval |

**The module is the same across all environments.** Only the input values change.
This means:
- A bug fix to the module's health probe logic fixes it everywhere
- A new guardrail (e.g., `require_cmek = true` for prod) deploys consistently
- Drift between environments is visible in the Terraform configs, not hidden in
  Console settings

---

## 8. The Alignment Playbook: Getting Teams On Board

### The Conversation Map (What You'll Actually Hear)

Extending the main strategy's resistance handling (Section 8):

| What the team says | What they really mean | Your response |
|---|---|---|
| "We just create it in Console, it's faster" | "Your process adds friction" | Show the PR flow: 10 min vs their 30 min in Console + no audit trail. "Console is faster for one service today. Module is faster for 80 teams forever." |
| "We don't know Terraform" | "Learning curve is too high" | "You write 7 lines. The module writes the other 200. And next quarter, the agent writes all 7 for you." |
| "What if the module doesn't support our use case?" | "We need flexibility" | "Show me. If the module is missing an input, we add it. You don't fork — you contribute." |
| "We already have our own Terraform" | "We've invested effort, don't invalidate it" | "Let's compare. Usually 80% of your code is boilerplate the module handles. You keep the 20% that's unique." |
| "Who reviews and approves PRs? We don't want bottlenecks" | "Your approval gate will slow us down" | "Dev auto-approves. Staging: team lead. Prod: platform review. Most teams get sub-hour turnaround." |
| "What happens when Terraform breaks at 2 AM?" | "We don't want to debug your code at 2 AM" | "The module team handles module bugs. You handle your config inputs. Clear ownership boundary." |

### The Enablement Sequence (Pull, Don't Push)

Following the main strategy's 5-Wave Adoption Model (Section 5.2):

```
Wave 0 (Month 1): Lighthouse
  Platform team migrates 2 teams' manually-created Cloud Run services
  into the module. White-glove. Record before/after.
  Before: "Who owns this service?" — 45 min to find out
  After: kubectl get cloudrun -l team=marketing-web — instant

Wave 1 (Month 2-3): Early Adopters
  Publish the module. Weekly office hours.
  "Here's the module. Here's an example. Here's a Slack channel."
  Teams that adopt start seeing: faster deploys, zero cost incidents,
  clean billing reports.

Wave 2 (Month 4-6): The Tipping Point
  Other teams see marketing-web deploying in 10 minutes while they
  wait 2 weeks on Jira tickets. They ask to onboard.
  Agent (Pillar 3) now handles: "Deploy a new service" → generates
  module call → opens PR → plan → merge → live.

Wave 3 (Month 7-9): Late Majority
  DORA metrics dashboard shows platform teams at 12 deploys/week
  vs. manual teams at 1.2/week. Peer pressure does the work.
  Migration hackathons for holdouts.

Wave 4 (Month 10-12): Sunset Manual
  "77% of teams already migrated voluntarily. Continuing to support
  Console-created infrastructure for the remaining teams is not viable."
  Mandate is politically safe because adoption already happened.
```

---

## 9. Measuring IaC Platform Success

| Metric | Before Platform | Target (12 Months) | How to Measure |
|---|---|---|---|
| Time to provision new service | 1-2 weeks (Jira ticket) | < 10 minutes (PR + apply) | PR creation-to-deploy time |
| Cost incidents from scaling | 2-3 per quarter | 0 | Billing alerts |
| Unlabeled resources | ~40% of Cloud Run services | 0% | `gcloud asset search --filter labels.team=""` |
| Config drift (Console changes) | Unknown | 0% | Weekly `terraform plan` drift check |
| Incident MTTR (finding owner) | 45 minutes | < 5 minutes | Labels → PagerDuty routing |
| Security violations (image source) | Monthly audit findings | Blocked at plan time | Validation error count |
| IaC coverage (% of infra in Terraform) | ~30% | 90%+ | Asset inventory vs. Terraform state |
| Developer satisfaction with IaC | Not measured | NPS > +30 | Monthly survey |

---

## 10. The Bottom Line: What This Module Really Is

This Terraform module is not infrastructure code. It's the **encoded institutional
memory** of every incident, every compliance finding, every cost overrun, and every
2 AM on-call page your organization has experienced.

When a new developer joins in Month 6, they won't know about the $14K incident.
Won't know about the DockerHub supply chain violation. Won't know about the
unlabeled service nobody could trace at 2 AM. **They don't need to know.**
The module remembers for them.

When the AI agent (Pillar 3) generates infrastructure on behalf of a developer,
it goes through the same module. Same validations. Same defaults. Same guardrails.
The agent doesn't know a shortcut the module doesn't — because there isn't one.

When a senior engineer leaves the company, their knowledge doesn't leave with them.
It's in the validation blocks. It's in the default values. It's in the error
messages that say "The $14K incident taught us this."

**That's the platform engineer's job on the ground:** not to build infrastructure,
but to encode organizational knowledge into self-service tools that make every team
as capable as the best team — automatically, consistently, permanently.

That's what self-service with guardrails means. Not "here's Terraform, good luck."
Not "read the 40-page standards doc." Not "open a Jira ticket and wait."

Seven lines. Four required fields. Production-grade. Every lesson remembered.

---

**Document Version History**

| Version | Date | Changes |
|---|---|---|
| 1.0 | 2026-09-18 | Initial draft — aligns with Platform Adoption Strategy v1.0 |

*This document is a living strategy — updated as modules mature, incidents teach new
lessons, and adoption patterns emerge. All incident examples are composites from real
enterprise patterns (2024-2026 industry data).*

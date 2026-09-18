###############################################################################
# IDENTITY — who owns this, non-negotiable
###############################################################################

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.service_name))
    error_message = "Service name must be lowercase alphanumeric with hyphens, 3-63 chars."
  }
}

variable "region" {
  description = "GCP region for the Cloud Run service"
  type        = string
  default     = "us-central1"

  validation {
    condition     = contains(["us-central1", "us-east4", "europe-west1", "asia-south1"], var.region)
    error_message = "Region must be one of the org-approved regions. Contact platform team to add new regions."
  }
}

variable "team" {
  description = "Owning team name — used for labeling, cost attribution, and alerting routing"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.team))
    error_message = "Team name must be lowercase alphanumeric with hyphens."
  }
}

variable "cost_center" {
  description = "Finance cost center code — required for chargeback"
  type        = string

  validation {
    condition     = can(regex("^[A-Z]{2,4}-[0-9]{4,6}$", var.cost_center))
    error_message = "Cost center must match format: XX-NNNNN (e.g., MKT-40210, ENG-10050)."
  }
}

###############################################################################
# CONTAINER — what runs
###############################################################################

variable "image" {
  description = "Container image to deploy (full Artifact Registry path including tag/digest)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.pkg\\.dev/", var.image))
    error_message = "Images must come from Artifact Registry (*.pkg.dev). DockerHub and other public registries are blocked by org policy."
  }
}

variable "port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret Manager references mapped to env var names"
  type = map(object({
    secret_id = string
    version   = optional(string, "latest")
  }))
  default = {}
}

###############################################################################
# SCALING — guardrails that prevent cost incidents
###############################################################################

variable "min_instances" {
  description = "Minimum instances (0 = scale to zero). Prod should be >= 1."
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0 && var.min_instances <= 10
    error_message = "min_instances must be 0-10. Need more? Open a platform ticket — we'll right-size with you."
  }
}

variable "max_instances" {
  description = "Maximum instances. Hard ceiling prevents runaway cost."
  type        = number
  default     = 10

  validation {
    condition     = var.max_instances >= 1 && var.max_instances <= 50
    error_message = "max_instances must be 1-50. The $14K incident taught us this. Need >50? Platform team reviews the load test first."
  }
}

variable "cpu" {
  description = "CPU allocation"
  type        = string
  default     = "1"

  validation {
    condition     = contains(["0.5", "1", "2", "4"], var.cpu)
    error_message = "CPU must be 0.5, 1, 2, or 4. Standardized tiers keep cost predictable."
  }
}

variable "memory" {
  description = "Memory allocation"
  type        = string
  default     = "512Mi"

  validation {
    condition     = contains(["256Mi", "512Mi", "1Gi", "2Gi", "4Gi", "8Gi"], var.memory)
    error_message = "Memory must be one of: 256Mi, 512Mi, 1Gi, 2Gi, 4Gi, 8Gi. Standardized tiers."
  }
}

variable "concurrency" {
  description = "Maximum concurrent requests per instance"
  type        = number
  default     = 80

  validation {
    condition     = var.concurrency >= 1 && var.concurrency <= 250
    error_message = "Concurrency must be 1-250."
  }
}

variable "timeout" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300

  validation {
    condition     = var.timeout >= 10 && var.timeout <= 900
    error_message = "Timeout must be 10-900 seconds."
  }
}

###############################################################################
# SECURITY — defaults are locked down, you opt IN to exposure
###############################################################################

variable "service_account_email" {
  description = "Dedicated service account. Empty = Compute Engine default SA (flagged in security review)."
  type        = string
  default     = ""
}

variable "allow_unauthenticated" {
  description = "Allow public access. Defaults to false — services are private by default."
  type        = bool
  default     = false
}

variable "invoker_members" {
  description = "IAM members granted Cloud Run Invoker role (when allow_unauthenticated=false)"
  type        = list(string)
  default     = []
}

###############################################################################
# NETWORKING — private by default
###############################################################################

variable "vpc_connector" {
  description = "VPC connector name for private networking (full resource name)"
  type        = string
  default     = ""
}

variable "vpc_egress" {
  description = "VPC egress setting"
  type        = string
  default     = "private-ranges-only"

  validation {
    condition     = contains(["all-traffic", "private-ranges-only"], var.vpc_egress)
    error_message = "Must be 'all-traffic' or 'private-ranges-only'."
  }
}

variable "ingress" {
  description = "Ingress setting: who can reach this service"
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "Must be INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  }
}

###############################################################################
# LABELS — additional labels beyond the enforced ones
###############################################################################

variable "extra_labels" {
  description = "Additional labels (team, cost-center, managed-by, environment are set automatically)"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name — drives default behaviors"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

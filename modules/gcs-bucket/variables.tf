variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Bucket name (must be globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.name))
    error_message = "Bucket name must be 3-63 chars, lowercase alphanumeric with hyphens/dots/underscores."
  }
}

variable "location" {
  description = "Bucket location (region or multi-region)"
  type        = string
  default     = "US"

  validation {
    condition     = contains(["US", "EU", "us-central1", "us-east4", "europe-west1", "asia-south1"], var.location)
    error_message = "Location must be an org-approved region or multi-region."
  }
}

variable "team" {
  description = "Owning team — used for labeling and cost attribution"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.team))
    error_message = "Team name must be lowercase alphanumeric with hyphens."
  }
}

variable "cost_center" {
  description = "Finance cost center code"
  type        = string

  validation {
    condition     = can(regex("^[A-Z]{2,4}-[0-9]{4,6}$", var.cost_center))
    error_message = "Cost center must match format: XX-NNNNN (e.g., MKT-40210)."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "storage_class" {
  description = "Storage class"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Must be STANDARD, NEARLINE, COLDLINE, or ARCHIVE."
  }
}

variable "versioning" {
  description = "Enable object versioning (default: true for data safety)"
  type        = bool
  default     = true
}

variable "lifecycle_age_days" {
  description = "Auto-delete objects older than N days (0 = disabled)"
  type        = number
  default     = 0

  validation {
    condition     = var.lifecycle_age_days >= 0 && var.lifecycle_age_days <= 3650
    error_message = "Lifecycle age must be 0-3650 days."
  }
}

variable "force_destroy" {
  description = "Allow bucket deletion even with objects inside (DANGEROUS — disabled by default)"
  type        = bool
  default     = false
}

variable "extra_labels" {
  description = "Additional labels beyond the enforced ones"
  type        = map(string)
  default     = {}
}

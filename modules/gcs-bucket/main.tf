locals {
  enforced_labels = {
    managed-by  = "terraform"
    team        = var.team
    cost-center = var.cost_center
    environment = var.environment
  }

  all_labels = merge(var.extra_labels, local.enforced_labels)
}

resource "google_storage_bucket" "this" {
  name     = var.name
  project  = var.project_id
  location = var.location
  labels   = local.all_labels

  storage_class               = var.storage_class
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.force_destroy

  versioning {
    enabled = var.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_age_days > 0 ? [1] : []
    content {
      condition {
        age = var.lifecycle_age_days
      }
      action {
        type = "Delete"
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.versioning ? [1] : []
    content {
      condition {
        num_newer_versions = 5
      }
      action {
        type = "Delete"
      }
    }
  }
}

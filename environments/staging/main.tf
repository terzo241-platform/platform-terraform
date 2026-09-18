module "sample_nextjs_app" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  service_name = "sample-nextjs-app"
  region       = var.region
  image        = "${var.artifact_registry_repo}/sample-nextjs-app:latest"
  environment  = "staging"

  team        = "marketing-web"
  cost_center = "MKT-40210"

  cpu    = "1"
  memory = "512Mi"
  port   = 3000

  min_instances = 1
  max_instances = 5
  concurrency   = 80

  env_vars = {
    NODE_ENV = "production"
    APP_ENV  = "staging"
  }

  allow_unauthenticated = false
  ingress               = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  extra_labels = {
    app = "sample-nextjs-app"
  }
}

module "static_assets" {
  source = "../../modules/gcs-bucket"

  project_id  = var.project_id
  name        = "${var.project_id}-static-assets-staging"
  location    = var.region
  environment = "staging"

  team        = "marketing-web"
  cost_center = "MKT-40210"

  versioning         = true
  lifecycle_age_days = 180
}

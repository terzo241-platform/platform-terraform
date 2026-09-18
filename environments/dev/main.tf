module "sample_nextjs_app" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  service_name = "sample-nextjs-app"
  region       = var.region
  image        = "${var.artifact_registry_repo}/sample-nextjs-app:latest"
  environment  = "dev"

  team        = "marketing-web"
  cost_center = "MKT-40210"

  cpu    = "1"
  memory = "512Mi"
  port   = 3000

  min_instances = 0
  max_instances = 3
  concurrency   = 80

  env_vars = {
    NODE_ENV = "production"
    APP_ENV  = "dev"
  }

  allow_unauthenticated = true
  ingress               = "INGRESS_TRAFFIC_ALL"

  extra_labels = {
    app = "sample-nextjs-app"
  }
}

module "static_assets" {
  source = "../../modules/gcs-bucket"

  project_id  = var.project_id
  name        = "${var.project_id}-static-assets-dev"
  location    = var.region
  environment = "dev"

  team        = "marketing-web"
  cost_center = "MKT-40210"

  versioning         = true
  lifecycle_age_days = 90
}

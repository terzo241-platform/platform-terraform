module "sample_nextjs_app" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  service_name = "sample-nextjs-app"
  region       = var.region
  image        = "${var.artifact_registry_repo}/sample-nextjs-app:latest"
  environment  = "prod"

  team        = "marketing-web"
  cost_center = "MKT-40210"

  cpu    = "2"
  memory = "1Gi"
  port   = 3000

  min_instances = 2
  max_instances = 20
  concurrency   = 80
  timeout       = 60

  env_vars = {
    NODE_ENV = "production"
    APP_ENV  = "prod"
  }

  allow_unauthenticated = false
  ingress               = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  extra_labels = {
    app      = "sample-nextjs-app"
    critical = "true"
  }
}

module "static_assets" {
  source = "../../modules/gcs-bucket"

  project_id  = var.project_id
  name        = "${var.project_id}-static-assets-prod"
  location    = "US"
  environment = "prod"

  team        = "marketing-web"
  cost_center = "MKT-40210"

  versioning    = true
  force_destroy = false
}

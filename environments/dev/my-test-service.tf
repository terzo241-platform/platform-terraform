module "my_test_service" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  service_name = "my-test-service"
  region       = var.region
  image        = "${var.artifact_registry_repo}/my-test-service:latest"
  environment  = "dev"

  team        = "dev1"
  cost_center = "plt-100"

  cpu    = "1"
  memory = "512Mi"
  port   = 8080

  min_instances = 0
  max_instances = 3
  concurrency   = 80

  env_vars = {
    APP_ENV = "dev"
  }

  allow_unauthenticated = true
  ingress               = "INGRESS_TRAFFIC_ALL"

  extra_labels = {
    app = "my-test-service"
  }
}

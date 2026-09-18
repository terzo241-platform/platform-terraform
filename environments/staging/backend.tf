terraform {
  backend "gcs" {
    bucket = "terzo241-poc-tfstate"
    prefix = "environments/staging"
  }
}

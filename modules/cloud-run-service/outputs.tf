output "service_url" {
  description = "URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.this.uri
}

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.this.name
}

output "service_id" {
  description = "Full resource ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.this.id
}

output "latest_revision" {
  description = "Latest ready revision name"
  value       = google_cloud_run_v2_service.this.latest_ready_revision
}

output "location" {
  description = "Region where the service is deployed"
  value       = google_cloud_run_v2_service.this.location
}

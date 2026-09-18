output "sample_nextjs_app_url" {
  description = "URL of the sample-nextjs-app Cloud Run service"
  value       = module.sample_nextjs_app.service_url
}

output "sample_nextjs_app_revision" {
  description = "Latest revision of sample-nextjs-app"
  value       = module.sample_nextjs_app.latest_revision
}

output "static_assets_bucket" {
  description = "Static assets GCS bucket URL"
  value       = module.static_assets.url
}

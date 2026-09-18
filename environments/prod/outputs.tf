output "sample_nextjs_app_url" {
  description = "URL of the sample-nextjs-app Cloud Run service"
  value       = module.sample_nextjs_app.service_url
}

output "static_assets_bucket" {
  description = "Static assets GCS bucket URL"
  value       = module.static_assets.url
}

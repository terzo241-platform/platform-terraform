output "name" {
  description = "Bucket name"
  value       = google_storage_bucket.this.name
}

output "url" {
  description = "Bucket URL (gs://...)"
  value       = google_storage_bucket.this.url
}

output "self_link" {
  description = "Bucket self_link"
  value       = google_storage_bucket.this.self_link
}

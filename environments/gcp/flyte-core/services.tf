locals {
  enabled_services = [
    "servicenetworking.googleapis.com", 
    "container.googleapis.com",
    "compute.googleapis.com"
  ]
}

resource "google_project_service" "project" {
  for_each = toset(local.enabled_services)
  project  = local.project_id
  service  = each.key
  
}

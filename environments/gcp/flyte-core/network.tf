module "network" {
  source = "terraform-google-modules/network/google"

  project_id   = local.project_id
  network_name = local.name_prefix
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "gke"
      subnet_ip             = "10.10.10.0/24"
      subnet_region         = local.region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    gke = [
      {
        
        range_name    = "gke-pods"
        ip_cidr_range = "172.16.0.0/16"
      },
      {
        range_name    = "gke-services"
        ip_cidr_range = "192.168.0.0/24"
      },
    ]
  }
  depends_on = [ google_project_service.project ]
}

resource "google_compute_global_address" "service_networking" {
  name          = "${local.name_prefix}-service-networking"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.network.network_self_link
  depends_on = [google_project_service.project ]
}

resource "google_service_networking_connection" "default" {
  network                 = module.network.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.service_networking.name]
}




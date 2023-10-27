provider "google" {
  project = "flyte-terraform1"
  region  = "us-east1"
}

provider "google-beta" {
  project = "flyte-terraform1"
  region  = "us-east1"
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "kubectl" {
 host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate) 
  
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate) 
  }
}

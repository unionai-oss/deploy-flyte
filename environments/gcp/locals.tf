locals {
  application            = "flyte"
  environment            = "terraform2"
  name_prefix            = "${local.application}-${local.environment}"
  region                 = data.google_client_config.current.region
  project_id             = data.google_project.current.project_id
  workload_identity_pool = "${local.project_id}.svc.id.goog"
  flyte_projects         = ["flytesnacks"]
  flyte_domains          = ["development", "staging", "production"]
  flyte_ksas             = ["default", "spark"]
}

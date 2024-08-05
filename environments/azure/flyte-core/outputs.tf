

output "cluster_endpoint" {
  value = format("%s.%s.%s",local.flyte_domain_label,var.azure_region,"cloudapp.azure.com")
}


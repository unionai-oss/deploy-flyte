

output "cluster-url" {
  value = format("%s.%s.%s",local.flyte_domain_label,local.location,"cloudapp.azure.com")
}


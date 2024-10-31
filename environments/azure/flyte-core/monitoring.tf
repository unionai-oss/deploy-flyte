locals{
project_domain_combinations = [
    for pair in setproduct(local.flyte_projects, local.flyte_domains) :
    "${pair[0]}-${pair[1]}"
  ]
  namespaces_for_data_collection = concat(
    ["kube-system", "gatekeeper-system", "flyte",
    local.project_domain_combinations]
  )
}
resource "azurerm_log_analytics_workspace" "flyte_logs" {
  name                = "${local.tenant}-${local.environment}"
  location            = azurerm_resource_group.flyte.location
  resource_group_name = azurerm_resource_group.flyte.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "MSCI-${azurerm_log_analytics_workspace.flyte_logs.location}-${azurerm_kubernetes_cluster.flyte.name}"
  resource_group_name = azurerm_resource_group.flyte.name
  location            = azurerm_log_analytics_workspace.flyte_logs.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.flyte_logs.id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = var.streams
    destinations = ["ciworkspace"]
  }

  data_flow {
    streams      = [ "Microsoft-Syslog"]
    destinations = ["ciworkspace"]
  }

  data_sources {
    syslog{
      streams            = ["Microsoft-Syslog"]
      facility_names      = var.syslog_facilities
      log_levels          = var.syslog_levels
      name               = "sysLogsDataSource"
    }
 
    extension {
      streams            = var.streams
      extension_name     = "ContainerInsights"
      extension_json     = jsonencode({
        "dataCollectionSettings" : {
            "interval": var.data_collection_interval,
            "namespaceFilteringMode": var.namespace_filtering_mode_for_data_collection,
            "namespaces": local.namespaces_for_data_collection
            "enableContainerLogV2": true
        }
      })
      name               = "ContainerInsightsExtension"
    }
  }

  description = "DCR for Azure Monitor Container Insights"
}

resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                        = "ContainerInsightsExtension"
  target_resource_id          = azurerm_kubernetes_cluster.flyte.id
  data_collection_rule_id     = azurerm_monitor_data_collection_rule.dcr.id
  description                 = "Association of container insights data collection rule. Deleting this association will break the data collection for this AKS Cluster."
}

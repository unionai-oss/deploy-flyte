variable "subscription_id"{ 
   type = string
 }

variable "tenant_id"{
  type = string
}

#Azure region or zone
variable "azure_region" {
type = string
}

## Monitoring variables
variable "streams" {
 default = ["Microsoft-ContainerLog", "Microsoft-ContainerLogV2", "Microsoft-KubeEvents", "Microsoft-KubePodInventory", "Microsoft-KubeNodeInventory", "Microsoft-KubePVInventory","Microsoft-KubeServices", "Microsoft-KubeMonAgentEvents", "Microsoft-InsightsMetrics", "Microsoft-ContainerInventory",  "Microsoft-ContainerNodeInventory", "Microsoft-Perf"]
}

variable "syslog_levels" {
  type = list(string)
  default = ["Debug", "Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency"]
}

variable "syslog_facilities" {
  type = list(string)
  default = ["auth", "authpriv", "cron", "daemon", "mark", "kern", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7", "lpr", "mail", "news", "syslog", "user", "uucp"]
}

variable "data_collection_interval" {
  default = "1m"
}

variable "namespace_filtering_mode_for_data_collection" {
  default = "Off"
}


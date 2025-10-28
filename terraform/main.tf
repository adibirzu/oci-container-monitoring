#######################################
# OCI Container Instance Monitoring
# Main Terraform Configuration
#######################################

locals {
  # Container environment variables (already a map)
  container_env_map = var.container_env_vars

  # NSG OCIDs (already a list)
  nsg_list = var.nsg_ocids

  # Common tags
  common_tags = merge(
    var.freeform_tags,
    {
      Project     = "OCI-Container-Monitoring"
      Terraform   = "true"
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    }
  )
}

#######################################
# IAM Policies and Dynamic Groups
#######################################
module "iam" {
  source = "./modules/iam"

  tenancy_ocid              = var.tenancy_ocid
  compartment_ocid          = var.compartment_ocid
  resource_prefix           = var.container_instance_name
  create_dynamic_groups     = true
  create_policies           = true
  enable_management_agent   = var.enable_management_agent
  enable_alarms             = var.enable_alarms

  freeform_tags = local.common_tags
}

#######################################
# Container Instance Deployment
#######################################
module "container_instance" {
  source = "./modules/container-instance"

  tenancy_ocid            = var.tenancy_ocid
  compartment_ocid        = var.compartment_ocid
  container_instance_name = var.container_instance_name
  container_image         = var.container_image
  container_shape         = var.container_shape
  container_ocpus         = var.container_ocpus
  container_memory_gb     = var.container_memory_gb
  container_count         = var.container_count
  container_port          = var.container_port
  container_env_vars      = local.container_env_map
  availability_domain     = var.availability_domain
  subnet_ocid             = var.subnet_ocid
  assign_public_ip        = var.assign_public_ip
  nsg_ocids               = local.nsg_list
  ocir_username           = var.ocir_username
  ocir_auth_token         = var.ocir_auth_token

  # Management Agent sidecar configuration
  enable_management_agent    = var.enable_management_agent
  mgmt_agent_install_key     = var.enable_management_agent ? module.management_agent[0].install_key : ""
  region                     = var.region
  prometheus_scrape_interval = var.prometheus_scrape_interval
  prometheus_scrape_timeout  = var.prometheus_scrape_timeout
  prometheus_metrics_port    = var.prometheus_metrics_port
  prometheus_metrics_path    = var.prometheus_metrics_path
  metrics_namespace          = var.metrics_namespace

  freeform_tags = local.common_tags
  defined_tags  = var.defined_tags

  depends_on = [module.iam, module.management_agent]
}

#######################################
# Logging Configuration
#######################################
module "logging" {
  count = var.enable_logging ? 1 : 0

  source = "./modules/logging"

  compartment_ocid        = var.compartment_ocid
  log_group_name          = var.log_group_name
  container_instance_id   = module.container_instance.container_instance_id
  enable_logging          = var.enable_logging
  enable_audit_logs       = var.enable_audit_logs
  enable_management_agent = var.enable_management_agent
  log_retention_days      = var.log_retention_days

  freeform_tags = local.common_tags
  defined_tags  = var.defined_tags

  depends_on = [module.container_instance]
}

#######################################
# Management Agent Install Key
# Note: For sidecar pattern, we only need the install key
# The agent configuration is done within the container instance
#######################################
module "management_agent" {
  count = var.enable_management_agent ? 1 : 0

  source = "./modules/management-agent"

  compartment_ocid           = var.compartment_ocid
  region                     = var.region
  install_key_name           = var.mgmt_agent_install_key_name
  prometheus_scrape_interval = var.prometheus_scrape_interval
  prometheus_metrics_port    = var.prometheus_metrics_port
  prometheus_metrics_path    = var.prometheus_metrics_path
  prometheus_targets         = []  # Empty for sidecar - scrapes localhost
  prometheus_job_name        = "container-${var.container_instance_name}"
  metrics_namespace          = var.metrics_namespace
  container_instance_id      = ""  # Not needed for sidecar pattern
  container_private_ip       = ""  # Not needed for sidecar pattern
  output_directory           = "${path.root}/output"

  additional_prometheus_labels = {
    container_name = var.container_instance_name
    environment    = lookup(var.freeform_tags, "Environment", "Development")
  }

  freeform_tags = local.common_tags

  depends_on = [module.iam]
}

#######################################
# Monitoring Alarms (Optional)
#######################################
resource "oci_monitoring_alarm" "cpu_alarm" {
  count              = var.enable_alarms ? 1 : 0
  compartment_id     = var.compartment_ocid
  display_name       = "${var.container_instance_name}-cpu-alarm"
  is_enabled         = true
  metric_compartment_id = var.compartment_ocid
  namespace          = "oci_computecontainerinstance"

  query = <<-EOT
    CpuUtilization[1m]{resourceId = "${module.container_instance.container_instance_id}"}.mean() > ${var.cpu_alarm_threshold}
  EOT

  severity = "CRITICAL"

  destinations = var.notification_topic_ocid != "" ? [var.notification_topic_ocid] : []

  body = "CPU utilization for ${var.container_instance_name} exceeded ${var.cpu_alarm_threshold}%"

  repeat_notification_duration = "PT2H"

  freeform_tags = local.common_tags
}

resource "oci_monitoring_alarm" "memory_alarm" {
  count              = var.enable_alarms ? 1 : 0
  compartment_id     = var.compartment_ocid
  display_name       = "${var.container_instance_name}-memory-alarm"
  is_enabled         = true
  metric_compartment_id = var.compartment_ocid
  namespace          = "oci_computecontainerinstance"

  query = <<-EOT
    MemoryUtilization[1m]{resourceId = "${module.container_instance.container_instance_id}"}.mean() > ${var.memory_alarm_threshold}
  EOT

  severity = "CRITICAL"

  destinations = var.notification_topic_ocid != "" ? [var.notification_topic_ocid] : []

  body = "Memory utilization for ${var.container_instance_name} exceeded ${var.memory_alarm_threshold}%"

  repeat_notification_duration = "PT2H"

  freeform_tags = local.common_tags
}

#######################################
# Terraform Outputs
#######################################

output "container_instance_id" {
  description = "Container Instance OCID"
  value       = module.container_instance.container_instance_id
}

output "container_instance_name" {
  description = "Container Instance Name"
  value       = module.container_instance.container_instance_name
}

output "container_instance_state" {
  description = "Container Instance State"
  value       = module.container_instance.container_instance_state
}

output "container_private_ip" {
  description = "Container Instance Private IP"
  value       = module.container_instance.container_instance_private_ip
}

output "container_public_ip" {
  description = "Container Instance Public IP"
  value       = module.container_instance.container_instance_public_ip
}

output "log_group_id" {
  description = "Log Group OCID"
  value       = var.enable_logging ? module.logging[0].log_group_id : null
}

output "log_group_name" {
  description = "Log Group Name"
  value       = var.enable_logging ? module.logging[0].log_group_name : null
}

output "application_log_id" {
  description = "Application Log OCID"
  value       = var.enable_logging ? module.logging[0].application_log_id : null
}

output "system_log_id" {
  description = "System Log OCID"
  value       = var.enable_logging ? module.logging[0].system_log_id : null
}

output "management_agent_install_key_id" {
  description = "Management Agent Install Key OCID"
  value       = var.enable_management_agent ? module.management_agent[0].install_key_id : null
}

output "management_agent_install_key" {
  description = "Management Agent Install Key (Sensitive)"
  value       = var.enable_management_agent ? module.management_agent[0].install_key : null
  sensitive   = true
}

output "agent_install_script_path" {
  description = "Path to Management Agent installation script"
  value       = var.enable_management_agent ? module.management_agent[0].install_script_path : null
}

output "prometheus_config_path" {
  description = "Path to Prometheus configuration file"
  value       = var.enable_management_agent ? module.management_agent[0].prometheus_config_path : null
}

output "container_instance_dynamic_group_id" {
  description = "Container Instance Dynamic Group OCID"
  value       = module.iam.container_instance_dynamic_group_id
}

output "cpu_alarm_id" {
  description = "CPU Alarm OCID"
  value       = var.enable_alarms ? oci_monitoring_alarm.cpu_alarm[0].id : null
}

output "memory_alarm_id" {
  description = "Memory Alarm OCID"
  value       = var.enable_alarms ? oci_monitoring_alarm.memory_alarm[0].id : null
}

#######################################
# Console URLs
#######################################
output "container_instance_console_url" {
  description = "OCI Console URL for Container Instance"
  value       = "https://cloud.oracle.com/compute/container-instances/${module.container_instance.container_instance_id}?region=${var.region}"
}

output "logs_console_url" {
  description = "OCI Console URL for Logs"
  value       = var.enable_logging ? "https://cloud.oracle.com/logging/log-groups/${module.logging[0].log_group_id}?region=${var.region}" : null
}

output "monitoring_console_url" {
  description = "OCI Console URL for Monitoring"
  value       = "https://cloud.oracle.com/monitoring/alarms?region=${var.region}&compartmentId=${var.compartment_ocid}"
}

#######################################
# Summary Output
#######################################
output "deployment_summary" {
  description = "Deployment Summary"
  value = {
    container_instance = {
      id         = module.container_instance.container_instance_id
      name       = module.container_instance.container_instance_name
      state      = module.container_instance.container_instance_state
      private_ip = module.container_instance.container_instance_private_ip
      public_ip  = module.container_instance.container_instance_public_ip
    }
    logging = var.enable_logging ? {
      log_group_id   = module.logging[0].log_group_id
      application_log = module.logging[0].application_log_id
      system_log     = module.logging[0].system_log_id
    } : null
    management_agent = var.enable_management_agent ? {
      install_key_id    = module.management_agent[0].install_key_id
      config_files_path = "${path.root}/output"
    } : null
    alarms = var.enable_alarms ? {
      cpu_alarm    = oci_monitoring_alarm.cpu_alarm[0].id
      memory_alarm = oci_monitoring_alarm.memory_alarm[0].id
    } : null
  }
}

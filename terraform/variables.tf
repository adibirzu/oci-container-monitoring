#######################################
# Provider Variables
#######################################
variable "region" {
  description = "OCI Region"
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "User OCID"
  type        = string
  default     = ""
}

variable "fingerprint" {
  description = "API Key Fingerprint"
  type        = string
  default     = ""
}

variable "private_key_path" {
  description = "Path to Private Key"
  type        = string
  default     = ""
}

variable "compartment_ocid" {
  description = "Compartment OCID where resources will be created"
  type        = string
}

#######################################
# Container Instance Variables
#######################################
variable "container_instance_name" {
  description = "Display name for Container Instance"
  type        = string
  default     = "monitoring-demo-instance"
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
  default     = "nginx:latest"
}

variable "container_shape" {
  description = "Container Instance shape"
  type        = string
  default     = "CI.Standard.E4.Flex"
}

variable "container_ocpus" {
  description = "Number of OCPUs"
  type        = number
  default     = 1
}

variable "container_memory_gb" {
  description = "Memory in GB"
  type        = number
  default     = 4
}

variable "container_count" {
  description = "Number of container replicas"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Container port to expose"
  type        = number
  default     = 80
}

variable "container_env_vars" {
  description = "Environment variables for container"
  type        = map(string)
  default     = {}
}

variable "availability_domain" {
  description = "Availability Domain number (1, 2, or 3)"
  type        = number
  default     = 1
}

#######################################
# Networking Variables
#######################################
variable "vcn_ocid" {
  description = "VCN OCID"
  type        = string
}

variable "subnet_ocid" {
  description = "Subnet OCID for Container Instance"
  type        = string
}

variable "assign_public_ip" {
  description = "Assign public IP to container instance"
  type        = bool
  default     = true
}

variable "nsg_ocids" {
  description = "List of Network Security Group OCIDs"
  type        = list(string)
  default     = []
}

#######################################
# Logging Variables
#######################################
variable "enable_logging" {
  description = "Enable container logging"
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Log Group display name"
  type        = string
  default     = "container-instance-logs"
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "enable_audit_logs" {
  description = "Enable audit logging"
  type        = bool
  default     = true
}

#######################################
# Management Agent Variables
#######################################
variable "enable_management_agent" {
  description = "Enable Management Agent for Prometheus metrics"
  type        = bool
  default     = true
}

variable "mgmt_agent_name" {
  description = "Management Agent display name"
  type        = string
  default     = "container-prometheus-agent"
}

variable "mgmt_agent_install_key_name" {
  description = "Management Agent install key name"
  type        = string
  default     = "container-agent-key"
}

variable "prometheus_scrape_interval" {
  description = "Prometheus scrape interval in seconds"
  type        = number
  default     = 60
}

variable "prometheus_scrape_timeout" {
  description = "Prometheus scrape timeout in seconds"
  type        = number
  default     = 10
}

variable "prometheus_metrics_port" {
  description = "Prometheus metrics port"
  type        = number
  default     = 9090
}

variable "prometheus_metrics_path" {
  description = "Prometheus metrics path"
  type        = string
  default     = "/metrics"
}

#######################################
# Monitoring Variables
#######################################
variable "create_dashboard" {
  description = "Create monitoring dashboard"
  type        = bool
  default     = true
}

variable "dashboard_name" {
  description = "Dashboard display name"
  type        = string
  default     = "Container Instance Monitoring Dashboard"
}

variable "metrics_namespace" {
  description = "Custom metrics namespace"
  type        = string
  default     = "container_monitoring"
}

variable "notification_topic_ocid" {
  description = "Notification topic OCID for alarms"
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "Enable metric alarms"
  type        = bool
  default     = false
}

variable "cpu_alarm_threshold" {
  description = "CPU alarm threshold percentage"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory alarm threshold percentage"
  type        = number
  default     = 80
}

#######################################
# Image Registry Variables
#######################################
variable "ocir_username" {
  description = "OCIR username for private images"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ocir_auth_token" {
  description = "OCIR auth token for private images"
  type        = string
  default     = ""
  sensitive   = true
}

#######################################
# Tags
#######################################
variable "freeform_tags" {
  description = "Freeform tags for resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

variable "defined_tags" {
  description = "Defined tags for resources"
  type        = map(string)
  default     = {}
}

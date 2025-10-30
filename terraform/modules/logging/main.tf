#######################################
# OCI Logging Module
# Creates log groups and logs for Container Instance monitoring
#######################################

#######################################
# Log Group for Container Instances
#######################################
resource "oci_logging_log_group" "container_log_group" {
  compartment_id = var.compartment_ocid
  display_name   = var.log_group_name
  description    = "Log group for container instance logs and monitoring"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

#######################################
# Container Application Logs (stdout/stderr)
# Using CUSTOM log type for Log Forwarder sidecar integration
#######################################
resource "oci_logging_log" "container_application_log" {
  display_name = "${var.log_group_name}-application"
  log_group_id = oci_logging_log_group.container_log_group.id
  log_type     = "CUSTOM"

  configuration {
    source {
      category    = "custom"
      resource    = var.compartment_ocid
      service     = "containerinstances"
      source_type = "OCISERVICE"
    }

    compartment_id = var.compartment_ocid
  }

  is_enabled       = var.enable_logging
  retention_duration = var.log_retention_days

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  depends_on = [oci_logging_log_group.container_log_group]
}

#######################################
# Container System Logs
# Using CUSTOM log type for Log Forwarder sidecar integration
#######################################
resource "oci_logging_log" "container_system_log" {
  display_name = "${var.log_group_name}-system"
  log_group_id = oci_logging_log_group.container_log_group.id
  log_type     = "CUSTOM"

  configuration {
    source {
      category    = "custom"
      resource    = var.compartment_ocid
      service     = "containerinstances"
      source_type = "OCISERVICE"
    }

    compartment_id = var.compartment_ocid
  }

  is_enabled       = var.enable_logging
  retention_duration = var.log_retention_days

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  depends_on = [oci_logging_log_group.container_log_group]
}

#######################################
# Audit Logs (Optional)
# Using CUSTOM log type for sidecar integration
#######################################
resource "oci_logging_log" "container_audit_log" {
  count        = var.enable_audit_logs ? 1 : 0
  display_name = "${var.log_group_name}-audit"
  log_group_id = oci_logging_log_group.container_log_group.id
  log_type     = "CUSTOM"

  configuration {
    source {
      category    = "custom"
      resource    = var.compartment_ocid
      service     = "containerinstances"
      source_type = "OCISERVICE"
    }

    compartment_id = var.compartment_ocid
  }

  is_enabled       = true
  retention_duration = var.log_retention_days

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  depends_on = [oci_logging_log_group.container_log_group]
}

#######################################
# Custom Log for Prometheus Metrics
#######################################
resource "oci_logging_log" "prometheus_metrics_log" {
  count        = var.enable_management_agent ? 1 : 0
  display_name = "${var.log_group_name}-prometheus-metrics"
  log_group_id = oci_logging_log_group.container_log_group.id
  log_type     = "CUSTOM"

  configuration {
    source {
      category    = "custom"
      resource    = var.compartment_ocid
      service     = "containerinstances"
      source_type = "OCISERVICE"
    }

    compartment_id = var.compartment_ocid
  }

  is_enabled       = true
  retention_duration = var.log_retention_days

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  depends_on = [oci_logging_log_group.container_log_group]
}

#######################################
# Log Analytics Integration (Optional)
#######################################
data "oci_logging_log_groups" "existing_log_analytics" {
  count          = var.enable_log_analytics ? 1 : 0
  compartment_id = var.compartment_ocid

  display_name = "LogAnalytics"
}

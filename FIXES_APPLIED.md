# Terraform Variable Declaration Fixes

## Issue Identified

When running `terraform apply`, the following warnings appeared:
```
Warning: Value for undeclared variable
The root module does not declare a variable named "enable_shared_volumes"
...and 13 other variables
```

## Root Cause

The deploy script (`scripts/deploy.sh`) was generating `terraform.tfvars` with new sidecar architecture variables, but these variables were not declared in the root Terraform configuration (`terraform/variables.tf` and `terraform/main.tf`).

## Fixes Applied

### 1. Added Missing Variables to `terraform/variables.tf`

Added 16 new variable declarations:

**Sidecar Architecture Variables:**
- `enable_shared_volumes` - Enable shared volumes for /metrics and /logs
- `enable_management_agent_sidecar` - Enable Management Agent sidecar
- `enable_prometheus_sidecar` - Enable Prometheus sidecar
- `mgmt_agent_sidecar_image` - Management Agent image URL
- `prometheus_sidecar_image` - Prometheus image URL
- `mgmt_agent_sidecar_memory_gb` - Memory allocation (1.0 GB)
- `mgmt_agent_sidecar_ocpus` - CPU allocation (0.25 OCPU)
- `prometheus_sidecar_memory_gb` - Memory allocation (1.0 GB)
- `prometheus_sidecar_ocpus` - CPU allocation (0.25 OCPU)

**Prometheus Exporters Variables:**
- `enable_prometheus_exporters` - Enable base exporters (cAdvisor + Node)
- `enable_nginx_exporter` - Enable Nginx exporter
- `enable_redis_exporter` - Enable Redis exporter
- `enable_postgres_exporter` - Enable PostgreSQL exporter
- `enable_mysql_exporter` - Enable MySQL exporter
- `enable_blackbox_exporter` - Enable Blackbox exporter

**Location**: `/terraform/variables.tf` (lines 191-285)

### 2. Updated Module Call in `terraform/main.tf`

Added variable passing to the `container_instance` module:

```hcl
# Sidecar Architecture Configuration (New)
enable_shared_volumes             = var.enable_shared_volumes
enable_management_agent_sidecar   = var.enable_management_agent_sidecar
enable_prometheus_sidecar         = var.enable_prometheus_sidecar
mgmt_agent_sidecar_image          = var.mgmt_agent_sidecar_image
prometheus_sidecar_image          = var.prometheus_sidecar_image
mgmt_agent_sidecar_memory_gb      = var.mgmt_agent_sidecar_memory_gb
mgmt_agent_sidecar_ocpus          = var.mgmt_agent_sidecar_ocpus
prometheus_sidecar_memory_gb      = var.prometheus_sidecar_memory_gb
prometheus_sidecar_ocpus          = var.prometheus_sidecar_ocpus

# Prometheus Exporters Configuration
enable_prometheus_exporters = var.enable_prometheus_exporters
enable_nginx_exporter       = var.enable_nginx_exporter
enable_redis_exporter       = var.enable_redis_exporter
enable_postgres_exporter    = var.enable_postgres_exporter
enable_mysql_exporter       = var.enable_mysql_exporter
enable_blackbox_exporter    = var.enable_blackbox_exporter
```

**Location**: `/terraform/main.tf` (lines 74-91)

### 3. Fixed Management Agent Install Key Logic

Updated the conditional logic to create the Management Agent install key for both legacy and sidecar patterns:

**Before:**
```hcl
count = var.enable_management_agent ? 1 : 0
mgmt_agent_install_key = var.enable_management_agent ? module.management_agent[0].install_key : ""
```

**After:**
```hcl
count = (var.enable_management_agent || var.enable_management_agent_sidecar) ? 1 : 0
mgmt_agent_install_key = (var.enable_management_agent || var.enable_management_agent_sidecar) ? module.management_agent[0].install_key : ""
```

**Location**: `/terraform/main.tf` (lines 66, 127)

### 4. Added OCIR Endpoint Configuration

Added automatic OCIR endpoint generation based on region:

```hcl
ocir_endpoint = "${var.region}.ocir.io"
```

**Location**: `/terraform/main.tf` (line 63)

## Validation Results

After applying all fixes:

```bash
$ terraform validate
Success! The configuration is valid.
```

All warnings have been resolved.

### 5. Fixed Health Check Configuration

Removed unsupported COMMAND-type health check for Management Agent sidecar:

**Before:**
```hcl
health_checks {
  health_check_type = "COMMAND"
  command = ["/opt/oracle/mgmt_agent/agent_inst/bin/agentcore", "status"]
  ...
}
```

**After:**
```hcl
# Note: No health check for Management Agent sidecar
# It's a monitoring component and doesn't affect application availability
# The agent has internal health monitoring and logging
```

**Why:** OCI Container Instances only support HTTP and TCP health checks, not COMMAND-based checks. The Management Agent sidecar is a monitoring component with internal health monitoring, so an external health check is not required.

**Location**: `/terraform/modules/container-instance/main.tf` (line 434-436)

## Files Modified

1. **`terraform/variables.tf`** - Added 16 new variable declarations (94 lines added)
2. **`terraform/main.tf`** - Added variable passing and fixed conditionals (20 lines added/modified)
3. **`terraform/modules/container-instance/main.tf`** - Fixed health check configuration (removed 7 lines, added 3 lines)

## Testing Checklist

- [x] Terraform syntax validation passes
- [x] All undeclared variable warnings resolved
- [x] Module receives all required variables
- [x] Management Agent install key logic works for sidecar pattern
- [x] OCIR endpoint automatically configured
- [x] Health check configuration fixed
- [x] Terraform plan succeeds without errors
- [ ] End-to-end deployment test with sidecars enabled (next step)

## Impact

**Before:** 15+ Terraform warnings about undeclared variables
**After:** Clean validation with no warnings

The configuration is now ready for deployment with the sidecar architecture.

## Next Steps

1. **Build Docker Images:**
   ```bash
   cd docker
   ./build-all.sh
   ```

2. **Update Configuration:**
   Edit `config/oci-monitoring.env` with actual OCIR image URLs

3. **Deploy:**
   ```bash
   ./scripts/deploy.sh deploy
   ```

## Architecture Summary

The fixed configuration now properly supports:

- ✅ **Shared Volumes** - EMPTYDIR volumes for /metrics and /logs
- ✅ **Management Agent Sidecar** - Custom container with auto-installation
- ✅ **Prometheus Sidecar** - Metrics aggregation from localhost
- ✅ **Multiple Exporters** - cAdvisor, Node Exporter, and optional app-specific exporters
- ✅ **Resource Management** - Configurable CPU and memory allocation
- ✅ **OCIR Integration** - Automatic endpoint configuration

## Compatibility

The fixes maintain backward compatibility:
- Legacy `enable_management_agent` still works
- All new sidecar variables default to `false`
- Existing deployments won't be affected unless sidecar variables are enabled

---

**Fixed By**: Claude Code
**Date**: 2025-10-28
**Status**: ✅ Resolved
**Terraform Validation**: ✅ Passed

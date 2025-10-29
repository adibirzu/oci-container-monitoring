# Critical Issues and Fixes

## Deployment Date: 2025-10-29
## Container Instance ID: ocid1.computecontainerinstance.oc1.eu-frankfurt-1.antheljrttkvkkia57t3w5u55ev27navf27vzc3qmokozda5wud7dwpkwpia

---

## ❌ Issue 1: Management Agent Not Registered

### Problem:
Management Agent sidecar is stuck at "Downloading Management Agent..." phase and never completes registration with OCI tenancy.

### Root Cause:
The entrypoint.sh script downloads the Management Agent from Oracle, but there may be issues with:
1. Network connectivity to Oracle's download servers
2. Agent RPM installation failing silently
3. setup.sh registration failing

### Current Log Output:
```
==========================================
OCI Management Agent Sidecar
==========================================
Region: eu-frankfurt-1
Metrics Namespace: container_monitoring
Prometheus Scrape Interval: 60s
==========================================
Downloading Management Agent...
[STUCK HERE - NO FURTHER OUTPUT]
```

### Fix Required:
1. Add verbose logging to entrypoint.sh to show download progress and errors
2. Add error handling for download failures
3. Add timeout for download operation
4. Verify the download URL is correct and accessible
5. Check if Resource Principal authentication is working for the container

### Action Items:
- [ ] Update `/docker/management-agent/entrypoint.sh` with verbose logging
- [ ] Add error handling and timeouts
- [ ] Test Management Agent registration manually
- [ ] Consider alternative: Use OCI Monitoring Connectors instead of Management Agent

---

## ❌ Issue 2: Log Forwarder Has No LOG_OCID

### Problem:
Log forwarder sidecar started successfully but has no OCI Log OCID to forward logs to.

### Root Cause:
1. Terraform logging module failed with error: `409-Conflict, A log group in the compartment already uses this display name`
2. Because logging module failed, no log OCID was created
3. Container was deployed with empty LOG_OCID environment variable

### Current Log Output:
```
2025-10-29 07:23:56,389 - log-forwarder - INFO -   Log OCID: Not configured
2025-10-29 07:23:56,389 - log-forwarder - INFO -   Batch Size: 100
2025-10-29 07:23:56,389 - log-forwarder - INFO -   Flush Interval: 5s
============================================================
OCI Log Forwarder Started
============================================================
Monitoring: /logs/application.log
```

### Fix Required:
1. Delete existing log group or use unique name
2. Re-run terraform apply to create logging resources
3. Update container with correct LOG_OCID environment variable

### Action Items:
- [ ] Delete existing log group: `oci logging log-group delete --log-group-id <OCID>`
- [ ] Or change log_group_name in terraform.tfvars to unique name
- [ ] Run `terraform apply` again to create logging module
- [ ] Redeploy container instance with correct LOG_OCID

---

## ❌ Issue 3: Prometheus Targets Showing localhost

### Problem:
Prometheus is configured with remote_write endpoint pointing to localhost:9091 (Management Agent receiver), but connection fails because:
1. Management Agent receiver is not running (agent not registered)
2. In sidecar architecture, scrape targets should be configured differently

### Current Log Output:
```
time=2025-10-29T07:23:51.114Z level=WARN source=queue_manager.go:2057 msg="Failed to send batch, retrying" component=remote remote_name=1446ed url=http://localhost:9091/api/v1/push err="Post \"http://localhost:9091/api/v1/push\": dial tcp [::1]:9091: connect: connection refused"
```

### Root Cause:
The Prometheus configuration (`/docker/prometheus/prometheus.yml`) has:
```yaml
remote_write:
  - url: http://localhost:9091/api/v1/push
```

This assumes Management Agent is exposing a receiver endpoint on port 9091, but:
1. Management Agent hasn't started yet
2. This architecture doesn't match OCI's recommended approach

### Fix Required:

#### Option A: Direct Scraping (Recommended for Sidecar)
Remove remote_write and let Prometheus just scrape and expose metrics:
1. Update `prometheus.yml` to remove remote_write section
2. Configure scrape jobs to target actual container IPs/hostnames
3. Use OCI Monitoring Connector Service to pull metrics from Prometheus

#### Option B: Keep Remote Write but Fix Targets
1. Wait for Management Agent to complete registration
2. Verify Management Agent receiver is running on port 9091
3. Update scrape targets to use proper service discovery

### Action Items:
- [ ] Update `/docker/prometheus/prometheus.yml` configuration
- [ ] Remove remote_write section
- [ ] Configure static_configs with proper scrape targets:
  ```yaml
  scrape_configs:
    - job_name: 'application'
      static_configs:
        - targets: ['127.0.0.1:8080']  # App metrics
    - job_name: 'cadvisor'
      static_configs:
        - targets: ['127.0.0.1:8080']  # cAdvisor
    - job_name: 'node-exporter'
      static_configs:
        - targets: ['127.0.0.1:9100']  # Node Exporter
  ```
- [ ] Rebuild prometheus-sidecar Docker image
- [ ] Redeploy container instance

---

## 🔧 Immediate Actions Required

### Step 1: Fix Logging Module Conflict
```bash
# Option A: Delete existing log group
oci logging log-group list --compartment-id ocid1.compartment.oc1..aaaaaaaagy3yddkkampnhj3cqm5ar7w2p7tuq5twbojyycvol6wugfav3ckq --display-name "container-instance-logs"

# Then delete it or...

# Option B: Use unique log group name
cd /Users/abirzu/dev/oci-monitoring/terraform
# Edit terraform.tfvars and change:
log_group_name = "container-instance-logs-v2"  # Or add timestamp
```

### Step 2: Simplify Architecture (Recommended)
Instead of the complex sidecar setup with Management Agent, consider:

```
Simplified Architecture:
├── Container 1: Application with Metrics (port 8080)
├── Container 2: Prometheus (port 9090)
│   └─ Scrapes: application:8080, cadvisor:8080, node-exporter:9100
└── Container 3: Log Forwarder (forwards to OCI Logging)
    └─ Reads: /logs volume

Then use OCI Monitoring Connector Service to:
- Pull metrics from Prometheus endpoint (port 9090)
- Send to OCI Monitoring Service
```

This eliminates the need for Management Agent sidecar entirely.

### Step 3: Update Prometheus Configuration
Create new prometheus.yml without remote_write:

```yaml
global:
  scrape_interval: 60s
  evaluation_interval: 60s
  external_labels:
    cluster: 'oci-container-monitoring'
    environment: 'production'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'application'
    static_configs:
      - targets: ['localhost:80']  # Main app
    metrics_path: /metrics

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']  # cAdvisor
    metrics_path: /metrics

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']  # Node Exporter
    metrics_path: /metrics
```

---

## 📝 Next Steps

1. **Choose Architecture Path:**
   - Path A: Fix Management Agent (complex, recommended for production scale)
   - Path B: Simplify to Prometheus + OCI Connector (easier, recommended for demo)

2. **Fix Logging Module:**
   - Delete or rename log group
   - Re-run terraform apply

3. **Update Prometheus:**
   - Remove remote_write configuration
   - Use localhost for scrape targets (sidecar pattern)
   - Rebuild and redeploy

4. **Test:**
   - Verify Prometheus UI at http://<public-ip>:9090
   - Check targets are UP
   - Verify logs are being forwarded to OCI Logging

---

## 🎯 Recommended Solution

**Use Simplified Sidecar Architecture without Management Agent:**

```
✅ Works out of the box
✅ No agent registration complexity
✅ Prometheus handles all scraping
✅ OCI Connector pulls from Prometheus
✅ Log Forwarder sends to OCI Logging directly
```

This is the most reliable approach for container-based monitoring.

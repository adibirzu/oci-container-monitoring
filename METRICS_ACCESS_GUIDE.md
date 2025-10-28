# How to View Your Metrics - Complete Guide

## 📊 Metrics Collection Architecture

Your monitoring system collects metrics at multiple levels:

```
┌─────────────────────────────────────────────────────────┐
│                 OCI Container Instance                  │
│                                                         │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────┐ │
│  │ Application │───▶│  Prometheus  │───▶│   Mgmt    │ │
│  │             │    │   Sidecar    │    │   Agent   │ │
│  │ Port 80     │    │   Port 9090  │    │  Sidecar  │ │
│  └─────────────┘    └──────────────┘    └─────┬─────┘ │
│         │                   │                  │       │
│         │            ┌──────▼──────┐           │       │
│         │            │   cAdvisor  │           │       │
│         │            │  Port 8080  │           │       │
│         │            └─────────────┘           │       │
│         │            ┌─────────────┐           │       │
│         └───────────▶│     Node    │           │       │
│                      │  Exporter   │           │       │
│                      │  Port 9100  │           │       │
│                      └─────────────┘           │       │
└──────────────────────────────────────────────┼─────────┘
                                                │
                                                ▼
                                     ┌──────────────────┐
                                     │ OCI Monitoring   │
                                     │    Service       │
                                     └──────────────────┘
```

---

## 🔍 Method 1: OCI Monitoring Console (Recommended)

### Access OCI Monitoring

1. **Login to OCI Console**: https://cloud.oracle.com
2. **Navigate to Monitoring**:
   - **Hamburger Menu** → **Observability & Management** → **Monitoring** → **Metrics Explorer**

3. **Select Your Compartment**:
   - Choose the compartment where your container instance is deployed

### View Container Metrics

**Query Builder Settings**:
```
Compartment: <your-compartment>
Metric Namespace: container_monitoring
Resource Group: <your-instance-name>-sidecar
```

**Available Metrics**:
- **Container Metrics** (from cAdvisor):
  - `container_cpu_usage_seconds_total` - CPU usage
  - `container_memory_usage_bytes` - Memory usage
  - `container_network_receive_bytes_total` - Network RX
  - `container_network_transmit_bytes_total` - Network TX
  - `container_fs_usage_bytes` - Filesystem usage

- **Host Metrics** (from Node Exporter):
  - `node_cpu_seconds_total` - Host CPU
  - `node_memory_MemTotal_bytes` - Total memory
  - `node_memory_MemAvailable_bytes` - Available memory
  - `node_disk_io_now` - Disk I/O
  - `node_network_receive_bytes_total` - Network stats

- **Application Metrics** (custom):
  - `app_requests_total` - Request counts
  - `app_request_duration_seconds` - Request duration
  - `app_active_connections` - Active connections

### Create Custom Charts

1. **Click "Add Query"** in Metrics Explorer
2. **Select Metric**:
   ```
   Metric Namespace: container_monitoring
   Metric Name: container_cpu_usage_seconds_total
   Interval: 1 minute
   Statistic: Average
   ```
3. **Add Dimension Filters**:
   - Filter by `container_name`, `pod_name`, etc.
4. **Save to Dashboard** for recurring viewing

---

## 🌐 Method 2: Direct Prometheus Access

### Access Prometheus UI

**Prerequisites**: Container instance must have public IP

1. **Get Container Public IP**:
   ```bash
   cd /Users/abirzu/dev/oci-monitoring/terraform
   terraform output container_public_ip
   ```

2. **Access Prometheus**:
   ```
   http://<PUBLIC_IP>:9090
   ```

### Prometheus Query Examples

**Container CPU Usage**:
```promql
rate(container_cpu_usage_seconds_total[5m])
```

**Memory Usage by Container**:
```promql
container_memory_usage_bytes{container_name!=""}
```

**Network Traffic**:
```promql
rate(container_network_receive_bytes_total[5m])
+ rate(container_network_transmit_bytes_total[5m])
```

**Application Requests per Second**:
```promql
rate(app_requests_total[1m])
```

**Host CPU Usage**:
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Prometheus UI Features

1. **Graph Tab**: Visualize metrics over time
2. **Targets Tab**: View scrape endpoints status
   - `http://<PUBLIC_IP>:9090/targets`
3. **Service Discovery**: View discovered services
4. **Alerts Tab**: View active alerts (if configured)

---

## 🔧 Method 3: Direct Exporter Access

### cAdvisor (Container Metrics)

**Access**: `http://<PUBLIC_IP>:8080/metrics`

**What you'll see**:
```
# HELP container_cpu_usage_seconds_total Cumulative cpu time consumed
# TYPE container_cpu_usage_seconds_total counter
container_cpu_usage_seconds_total{container_name="monitoring-demo-app"} 45.23

# HELP container_memory_usage_bytes Current memory usage in bytes
# TYPE container_memory_usage_bytes gauge
container_memory_usage_bytes{container_name="monitoring-demo-app"} 157286400
```

### Node Exporter (Host Metrics)

**Access**: `http://<PUBLIC_IP>:9100/metrics`

**What you'll see**:
```
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="user"} 1234.56

# HELP node_memory_MemTotal_bytes Memory information field MemTotal_bytes
# TYPE node_memory_MemTotal_bytes gauge
node_memory_MemTotal_bytes 4294967296
```

### Application Metrics

**Access**: `http://<PUBLIC_IP>:8081/metrics`

**What you'll see**:
```
# HELP app_requests_total Total number of requests
# TYPE app_requests_total counter
app_requests_total{method="GET",status="200"} 1523

# HELP app_request_duration_seconds Request duration in seconds
# TYPE app_request_duration_seconds histogram
app_request_duration_seconds_bucket{le="0.1"} 1200
```

---

## 📈 Method 4: Using OCI CLI

### Query Metrics via CLI

**Get Metric Data**:
```bash
# Set variables
COMPARTMENT_ID="ocid1.compartment.oc1..aaaaaaaagy3yddkkampnhj3cqm5ar7w2p7tuq5twbojyycvol6wugfav3ckq"
NAMESPACE="container_monitoring"
METRIC_NAME="container_cpu_usage_seconds_total"

# Query metrics
oci monitoring metric-data summarize-metrics-data \
  --compartment-id "$COMPARTMENT_ID" \
  --namespace "$NAMESPACE" \
  --query-text "ContainerCpuUsage[1m].mean()" \
  --start-time "2025-10-28T00:00:00Z" \
  --end-time "2025-10-28T23:59:59Z" \
  --resolution "1m"
```

**List Available Metrics**:
```bash
oci monitoring metric list \
  --compartment-id "$COMPARTMENT_ID" \
  --namespace "$NAMESPACE"
```

---

## 🖥️ Method 5: Container Logs

### View Container Logs

**List Containers**:
```bash
INSTANCE_ID=$(cd terraform && terraform output -raw container_instance_id)
COMPARTMENT_ID="ocid1.compartment.oc1..aaaaaaaagy3yddkkampnhj3cqm5ar7w2p7tuq5twbojyycvol6wugfav3ckq"

oci container-instances container list \
  --container-instance-id "$INSTANCE_ID" \
  --compartment-id "$COMPARTMENT_ID"
```

**View Logs for Specific Container**:
```bash
CONTAINER_ID="<container-ocid-from-above>"

oci container-instances container retrieve-logs \
  --container-id "$CONTAINER_ID" \
  --compartment-id "$COMPARTMENT_ID"
```

**View Prometheus Sidecar Logs**:
```bash
# Find Prometheus container ID first, then:
oci container-instances container retrieve-logs \
  --container-id "$PROMETHEUS_CONTAINER_ID" \
  --compartment-id "$COMPARTMENT_ID"
```

---

## 📊 Method 6: Creating Dashboards

### OCI Console Dashboard

1. **Navigate to Dashboards**:
   - **Observability & Management** → **Dashboards** → **Create Dashboard**

2. **Add Widgets**:
   - **Line Chart**: CPU usage over time
   - **Bar Chart**: Memory by container
   - **Gauge**: Current network throughput
   - **Table**: Container status

3. **Configure Widget**:
   ```
   Compartment: <your-compartment>
   Namespace: container_monitoring
   Metric: container_cpu_usage_seconds_total
   Statistic: Average
   Interval: 1m
   ```

### Grafana Integration (Optional)

If you want advanced visualization:

1. **Deploy Grafana**:
   ```bash
   docker run -d -p 3000:3000 grafana/grafana
   ```

2. **Add Prometheus as Data Source**:
   - URL: `http://<CONTAINER_PUBLIC_IP>:9090`

3. **Import Dashboard**:
   - Use dashboard ID `893` (cAdvisor) or `1860` (Node Exporter)

---

## 🔔 Method 7: Setting Up Alarms

### Create Alarm in OCI Console

1. **Navigate to Alarms**:
   - **Observability & Management** → **Monitoring** → **Alarm Definitions**

2. **Create Alarm**:
   ```
   Name: High CPU Usage
   Compartment: <your-compartment>
   Metric Namespace: container_monitoring
   Metric Name: container_cpu_usage_seconds_total

   Condition: Greater than 80%
   Trigger: For 5 minutes

   Notification: <your-topic-or-email>
   ```

---

## 🎯 Quick Access Commands

### Get Public IP
```bash
cd /Users/abirzu/dev/oci-monitoring/terraform
PUBLIC_IP=$(terraform output -raw container_public_ip)
echo "Public IP: $PUBLIC_IP"
```

### Test All Endpoints
```bash
PUBLIC_IP="<your-public-ip>"

# Application
curl http://$PUBLIC_IP/

# Prometheus
curl http://$PUBLIC_IP:9090/-/healthy

# cAdvisor metrics
curl http://$PUBLIC_IP:8080/metrics | head -20

# Node Exporter metrics
curl http://$PUBLIC_IP:9100/metrics | head -20

# Application metrics
curl http://$PUBLIC_IP:8081/metrics | head -20
```

---

## 📋 Metrics Summary Table

| Metric Source | Port | URL Path | What It Monitors |
|--------------|------|----------|------------------|
| **Prometheus** | 9090 | `/metrics` | Aggregated metrics |
| **cAdvisor** | 8080 | `/metrics` | Container stats |
| **Node Exporter** | 9100 | `/metrics` | Host system stats |
| **Application** | 8081 | `/metrics` | Custom app metrics |
| **Application UI** | 80 | `/` | Web interface |
| **Health Check** | 80 | `/health` | App health status |

---

## 🔍 Troubleshooting

### Can't Access Prometheus UI

**Check Security Rules**:
```bash
# Verify port 9090 is open
curl -I http://<PUBLIC_IP>:9090
```

**Check Container Status**:
```bash
oci container-instances container list \
  --container-instance-id "$INSTANCE_ID" \
  --compartment-id "$COMPARTMENT_ID" \
  --query 'data[?"display-name"==`monitoring-demo-prometheus-sidecar`]'
```

### No Metrics in OCI Monitoring

**Check Management Agent Status**:
```bash
# View agent logs
oci management-agent agent list \
  --compartment-id "$COMPARTMENT_ID" \
  --lifecycle-state "ACTIVE"
```

**Verify Prometheus Plugin**:
- Check container logs for management agent sidecar
- Ensure install key is valid
- Verify IAM policies are correct

### Metrics Not Updating

**Check Scrape Targets**:
- Open Prometheus UI: `http://<PUBLIC_IP>:9090/targets`
- All targets should show status "UP"
- If down, check exporter containers are running

---

## 📚 Additional Resources

- **OCI Monitoring Docs**: https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm
- **Prometheus Query Language**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **cAdvisor Metrics**: https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md
- **Node Exporter Metrics**: https://github.com/prometheus/node_exporter#enabled-by-default

---

**Last Updated**: 2025-10-28
**Your Container Instance**: monitoring-demo
**Compartment**: ocid1.compartment.oc1..aaaaaaaagy3yddkkampnhj3cqm5ar7w2p7tuq5twbojyycvol6wugfav3ckq

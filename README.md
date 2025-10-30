# OCI Container Instance Monitoring Demo

Production-ready monitoring solution for OCI Container Instances with sidecar-based Prometheus metrics collection, log forwarding, and automatic Management Agent registration.

## 🎯 Overview

This demo provides comprehensive container monitoring using a modern sidecar architecture:

- **📊 Sidecar-Based Monitoring**: Management Agent, Prometheus, and Log Forwarder run as sidecar containers
- **🔄 Automatic Registration**: Management Agent auto-registers with your OCI tenancy
- **📝 Log Forwarding**: Automatic log collection and forwarding to OCI Logging
- **🔒 Network Security**: NSG with automatic IP detection for secure access
- **📦 One-Command Deployment**: Fully automated infrastructure provisioning
- **🐳 Multi-Exporter Support**: cAdvisor, Node Exporter, and application-specific exporters

## 🏗️ Sidecar Architecture (7 Containers)

```
┌──────────────────────────────────────────────────────────────────────────┐
│              OCI Container Instance - 7 Containers                       │
│              Public IP: 130.61.110.78                                    │
│                                                                          │
│  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│  │  Application    │  │  Official Oracle │  │  Prometheus      │      │
│  │  Container      │  │  Mgmt Agent      │  │  Sidecar         │      │
│  │  + cAdvisor     │  │  Sidecar v1.9.0  │  │                  │      │
│  │  + Node Export. │  │                  │  │  - Aggregates    │      │
│  │                 │  │  - Auto-registers│◄─┤    all metrics   │      │
│  │  - App :80      │  │  - ConfigFile    │  │  - Scrapes :9090 │      │
│  │  - Metrics :9090│◄─┤    with input.rsp│  │  - Prometheus DB │      │
│  │  - cAdvisor:8080│  │  - Resource      │  └──────────────────┘      │
│  │  - Node Exp:9100│  │    Principal     │                            │
│  └────────┬────────┘  │  - Sends to OCI  │  ┌──────────────────┐      │
│           │           │    Monitoring    │  │  Grafana         │      │
│           │           └──────────────────┘  │  Sidecar         │      │
│           │                                 │                  │      │
│           │           ┌──────────────────┐  │  - Dashboards    │      │
│           │           │  Log Forwarder   │  │  - Prometheus DS │      │
│           └──────────►│  Sidecar         │  │  - Port :3000    │      │
│      Writes logs      │                  │  │  - admin/admin   │      │
│      to /logs         │  - Monitors /logs│◄─┼──Queries────────│      │
│                       │  - Batch forward │  │    Prometheus    │      │
│                       │  - OCI Logging   │  └──────────────────┘      │
│                       └──────────────────┘                            │
│                                                                          │
│  Shared Volumes:                                                         │
│  • /metrics  - Shared for metrics exchange                              │
│  • /logs     - Shared for log collection                                │
└──────────────────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────┴─────────┐
                    │                   │
              ┌─────▼──────┐    ┌──────▼───────┐
              │OCI          │    │OCI           │
              │Monitoring   │    │Logging       │
              │             │    │              │
              │Namespace:   │    │Log Group:    │
              │container_   │    │container-    │
              │monitoring   │    │instance-logs │
              └─────────────┘    └──────────────┘
```

## ✨ Key Features

### Automated Monitoring
- ✅ **Management Agent Auto-Registration**: Automatically registers with OCI tenancy using install key
- ✅ **Sidecar-Based Collection**: No agent installation needed on host
- ✅ **Prometheus Integration**: Metrics collected via Prometheus protocol
- ✅ **OCI Monitoring**: Metrics appear in `container_monitoring` namespace
- ✅ **Real-time Collection**: 60-second default scrape interval (configurable)

### Log Management
- ✅ **Automatic Log Forwarding**: Sidecar monitors and forwards logs to OCI Logging
- ✅ **Shared Volume Pattern**: Application writes to `/logs`, forwarder reads and sends
- ✅ **Batch Processing**: Efficient batching with configurable size
- ✅ **Resource Principal Auth**: Secure, credential-less authentication

### Network Security
- ✅ **Automatic IP Detection**: NSG automatically configured with your public IP
- ✅ **Port-Based Rules**: Secure access to all monitoring ports
- ✅ **Least Privilege**: Only necessary ports exposed to your IP

### Container Images Built
1. **Official Oracle Management Agent** - v1.9.0 from Oracle Container Registry
2. **Prometheus Sidecar** - Aggregates metrics from local endpoints
3. **Application with Metrics** - Sample app exposing Prometheus metrics (includes cAdvisor + Node Exporter)
4. **Log Forwarder Sidecar** - Monitors and forwards logs to OCI Logging
5. **Grafana Sidecar** - Pre-configured dashboards with Prometheus datasource

## 📋 Prerequisites

### Required Tools
- **Terraform** >= 1.0.0
- **OCI CLI** configured with valid credentials
- **Docker** for building container images
- **Git** for cloning repository

### OCI Resources Required
- OCI tenancy with appropriate compartment
- VCN with subnet
- OCIR (Oracle Cloud Infrastructure Registry) access
- IAM permissions for:
  - Container Instances
  - Management Agents
  - Monitoring
  - Logging
  - Networking (NSG creation)

### OCI IAM Policies

The solution automatically creates necessary IAM policies and dynamic groups. Required root-level policies:

```hcl
# Allow Container Instances to use OCI services
Allow dynamic-group <prefix>-container-instance-dg to manage all-resources in compartment <compartment>

# Allow Management Agent operations
Allow dynamic-group <prefix>-container-instance-dg to manage management-agents in compartment <compartment>
Allow dynamic-group <prefix>-container-instance-dg to use metrics in compartment <compartment>

# Allow log forwarding
Allow dynamic-group <prefix>-container-instance-dg to use log-content in compartment <compartment>
```

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/your-username/oci-container-monitoring-demo.git
cd oci-container-monitoring-demo
```

### 2. Configure Environment

```bash
# Copy example configuration
cp config/oci-monitoring.env.example config/oci-monitoring.env

# Edit configuration with your OCI details
vi config/oci-monitoring.env
```

**Required Configuration:**

```bash
# OCI Authentication
export OCI_REGION="eu-frankfurt-1"
export OCI_TENANCY_OCID="ocid1.tenancy.oc1..aaaa..."
export OCI_COMPARTMENT_OCID="ocid1.compartment.oc1..aaaa..."

# Networking
export VCN_OCID="ocid1.vcn.oc1..aaaa..."
export SUBNET_OCID="ocid1.subnet.oc1..aaaa..."

# OCIR Credentials (for pushing custom images)
export OCIR_USERNAME="<namespace>/<username>"
export OCIR_PASSWORD="<auth_token>"

# Container Configuration
export CONTAINER_INSTANCE_NAME="monitoring-demo"

# Sidecar Architecture (Enable all sidecars)
export ENABLE_SHARED_VOLUMES="true"
export ENABLE_MANAGEMENT_AGENT_SIDECAR="true"
export ENABLE_PROMETHEUS_SIDECAR="true"
export ENABLE_LOG_FORWARDER_SIDECAR="true"
```

### 3. Build and Push Container Images

```bash
cd docker
./build-all.sh
```

**What this does:**
- Builds 4 container images:
  1. Management Agent Sidecar
  2. Prometheus Sidecar
  3. Application with Metrics
  4. Log Forwarder Sidecar
- Pushes images to OCIR
- **Automatically updates** `config/oci-monitoring.env` with image URLs

**Output:**
```
✓ Configuration file updated successfully!

Updated image URLs:
  MGMT_AGENT_SIDECAR_IMAGE="fra.ocir.io/.../mgmt-agent-sidecar:1.0.0"
  PROMETHEUS_SIDECAR_IMAGE="fra.ocir.io/.../prometheus-sidecar:1.0.0"
  APP_WITH_METRICS_IMAGE="fra.ocir.io/.../app-with-metrics:1.0.0"
  LOG_FORWARDER_SIDECAR_IMAGE="fra.ocir.io/.../log-forwarder-sidecar:1.0.0"
```

### 4. Deploy Infrastructure

```bash
cd ..
./scripts/deploy.sh deploy
```

**Deployment includes:**
- ✅ IAM policies and dynamic groups
- ✅ Management Agent install key creation
- ✅ **NSG with automatic IP detection**
- ✅ Container Instance with all sidecars
- ✅ OCI Logging log group and logs
- ✅ Optional monitoring alarms

### 5. Verify Deployment

#### Check Management Agent Registration

```bash
# List Management Agents in your compartment
oci management-agent agent list \
  --compartment-id $OCI_COMPARTMENT_OCID \
  --lifecycle-state ACTIVE \
  --query 'data[*].{"Name":"display-name","State":"lifecycle-state","Host":"host"}' \
  --output table
```

**Expected Output:**
```
+---------------------------------+---------+---------------------------+
| Name                            | State   | Host                      |
+---------------------------------+---------+---------------------------+
| <hostname>-mgmt-agent          | ACTIVE  | monitoring-demo-app       |
+---------------------------------+---------+---------------------------+
```

#### View Metrics in OCI Console

1. Navigate to: **Observability & Management → Monitoring → Metrics Explorer**
2. Select your compartment
3. Choose namespace: **`container_monitoring`**
4. Select metrics:
   - `container_cpu_usage_seconds_total`
   - `container_memory_usage_bytes`
   - `app_requests_total` (custom metric)

#### View Logs in OCI Console

1. Navigate to: **Observability & Management → Logging → Logs**
2. Find log group: **`container-instance-logs`**
3. View logs:
   - **Application Log** - Application stdout/stderr
   - **System Log** - Container system logs

#### Check Container Status

```bash
# Get container instance details
oci container-instances container-instance get \
  --container-instance-id <instance-ocid> \
  --query 'data.{"State":"lifecycle-state","Containers":"containers[*].{Name:display-name,State:lifecycle-state}"}' \
  --output json
```

**Expected Output (7 Containers):**
```json
{
  "State": "ACTIVE",
  "Containers": [
    {
      "Name": "monitoring-demo-app",
      "State": "ACTIVE"
    },
    {
      "Name": "monitoring-demo-cadvisor",
      "State": "ACTIVE"
    },
    {
      "Name": "monitoring-demo-node-exporter",
      "State": "ACTIVE"
    },
    {
      "Name": "monitoring-demo-mgmt-agent-sidecar",
      "State": "ACTIVE"
    },
    {
      "Name": "monitoring-demo-prometheus-sidecar",
      "State": "ACTIVE"
    },
    {
      "Name": "monitoring-demo-log-forwarder-sidecar",
      "State": "ACTIVE"
    },
    {
      "Name": "monitoring-demo-grafana-sidecar",
      "State": "ACTIVE"
    }
  ]
}
```

#### Access Grafana Dashboard

Grafana is pre-configured with Prometheus datasource and comes with a Container Monitoring dashboard.

**Access URL**: `http://130.61.110.78:3000`

**Default Credentials**:
- Username: `admin`
- Password: `admin`

**What to verify:**
1. Login to Grafana
2. Navigate to **Dashboards** → You should see "Container Instance Monitoring Dashboard"
3. Check **Data Sources** → Prometheus should be pre-configured pointing to `http://localhost:9090`
4. View metrics:
   - Container CPU usage
   - Container memory usage
   - Network I/O
   - Custom application metrics

#### Access Prometheus Directly

```bash
# Prometheus web UI
curl http://130.61.110.78:9090

# Or open in browser
open http://130.61.110.78:9090
```

#### Access Container Metrics Exporters

```bash
# cAdvisor - Container metrics
curl http://130.61.110.78:8080/metrics

# Node Exporter - Host metrics
curl http://130.61.110.78:9100/metrics

# Application metrics
curl http://130.61.110.78/metrics
```

## 📊 Complete Workflow

### Phase 1: Build Container Images (docker/build-all.sh)

```
1. Login to OCIR
2. Build Management Agent Sidecar
   └─ Install Management Agent RPM
   └─ Configure registration script
3. Build Prometheus Sidecar
   └─ Configure scrape targets
4. Build Application with Metrics
   └─ Sample app with /metrics endpoint
5. Build Log Forwarder Sidecar
   └─ OCI SDK + watchdog library
6. Push all images to OCIR
7. AUTO-UPDATE config/oci-monitoring.env
   └─ Updates all image URLs automatically!
```

### Phase 2: Terraform Infrastructure (./scripts/deploy.sh deploy)

```
1. Initialize Terraform
2. Detect Your Public IP (automatic)
   └─ Uses https://ifconfig.me/ip
3. Create IAM Resources
   ├─ Dynamic Group for Container Instances
   ├─ Policies for Management Agent
   ├─ Policies for Monitoring
   └─ Policies for Logging
4. Create NSG with Your IP
   ├─ HTTP/HTTPS: 80, 443
   ├─ Prometheus: 9090
   ├─ cAdvisor: 8080
   ├─ Node Exporter: 9100
   └─ Optional exporters: 9104, 9113, 9115, 9121, 9187
5. Create Management Agent Install Key
6. Create Logging Resources
   ├─ Log Group
   ├─ Application Log
   └─ System Log
7. Deploy Container Instance
   ├─ Application Container
   ├─ Management Agent Sidecar
   ├─ Prometheus Sidecar
   └─ Log Forwarder Sidecar
8. Attach NSG to Container Instance
9. Configure Shared Volumes
   ├─ /metrics (App ↔ Prometheus)
   └─ /logs (App ↔ Log Forwarder)
```

### Phase 3: Container Startup & Registration

```
Application Container:
1. Starts application on port 80
2. Exposes Prometheus metrics on :9090/metrics
3. Writes logs to /logs/application.log

Management Agent Sidecar:
1. Downloads Management Agent RPM
2. Installs agent
3. Creates response file with install key
4. Runs setup.sh → REGISTERS WITH OCI
   ├─ Validates install key
   ├─ Generates communication wallet
   ├─ Generates security artifacts
   └─ Registers with Management Agent service
5. Configures Prometheus plugin
6. Starts agent (agentcore start)
7. Begins scraping localhost:9090/metrics
8. Forwards metrics to OCI Monitoring

Prometheus Sidecar:
1. Loads configuration
2. Scrapes localhost:9090/metrics every 60s
3. Aggregates metrics
4. Provides aggregated metrics to Management Agent

Log Forwarder Sidecar:
1. Monitors /logs directory using watchdog
2. Detects new log entries
3. Batches logs (configurable batch size)
4. Forwards to OCI Logging using Resource Principal
5. Continues monitoring for new logs
```

### Phase 4: Monitoring & Verification

```
OCI Management Agent Console:
1. Navigate to: Observability & Management → Management Agents
2. Find agent: <hostname>-mgmt-agent
3. Status: ACTIVE
4. Plugin: Prometheus (Enabled)

OCI Monitoring Console:
1. Navigate to: Observability & Management → Monitoring → Metrics Explorer
2. Namespace: container_monitoring
3. View metrics:
   ├─ container_cpu_usage_seconds_total
   ├─ container_memory_usage_bytes
   ├─ container_network_receive_bytes_total
   ├─ container_network_transmit_bytes_total
   ├─ node_cpu_seconds_total
   ├─ node_memory_MemAvailable_bytes
   └─ app_requests_total (custom)

OCI Logging Console:
1. Navigate to: Observability & Management → Logging → Logs
2. Log Group: container-instance-logs
3. Logs:
   ├─ Application Log (from /logs/application.log)
   └─ System Log (container system events)
```

## 🗂️ Project Structure

```
oci-container-monitoring-demo/
├── config/
│   └── oci-monitoring.env          # Main configuration (auto-updated by build-all.sh)
├── docker/
│   ├── build-all.sh                # Builds all 4 images + AUTO-UPDATES .env
│   ├── management-agent/
│   │   ├── Dockerfile
│   │   └── entrypoint.sh           # Agent registration & startup
│   ├── prometheus/
│   │   ├── Dockerfile
│   │   └── prometheus.yml
│   ├── app-with-metrics/
│   │   ├── Dockerfile
│   │   └── app.py                  # Sample app with /metrics
│   └── log-forwarder/
│       ├── Dockerfile
│       ├── log-forwarder.py        # Monitors /logs and forwards to OCI
│       └── config.json.template
├── terraform/
│   ├── main.tf                     # Main config + NSG module
│   ├── variables.tf
│   ├── outputs.tf                  # Includes detected IP & NSG info
│   └── modules/
│       ├── container-instance/     # Container Instance + sidecars
│       ├── iam/                    # Policies + dynamic groups
│       ├── logging/                # OCI Logging resources
│       ├── management-agent/       # Install key creation
│       └── nsg/                    # Network Security Group
├── scripts/
│   └── deploy.sh                   # Deployment orchestration
└── README.md                       # This file
```

## 📡 Management Agent Prometheus Data Source

The Management Agent uses the Prometheus plugin to collect metrics and forward them to OCI Monitoring. This section explains how it's configured and how metrics flow from Prometheus to OCI.

### How It Works

```
Application Metrics (:9090/metrics)
    ↓
Prometheus Sidecar (aggregates)
    ↓
Management Agent (scrapes Prometheus)
    ↓
OCI Monitoring (container_monitoring namespace)
```

### Configuration

The Management Agent Prometheus plugin is automatically configured using the **ConfigFile** volume with `input.rsp`:

```bash
# Automatically created by Terraform in ConfigFile volume
ManagementAgentInstallKey=${MGMT_AGENT_INSTALL_KEY}
AgentDisplayName=${CONTAINER_INSTANCE_NAME}-mgmt-agent
CredentialWalletPassword=${AUTO_GENERATED_PASSWORD}
Service.plugin.prometheus.download=true  # Downloads Prometheus plugin
```

### Prometheus Plugin Configuration

The plugin configuration is automatically created at agent startup:

**Location**: `/opt/oracle/mgmt_agent/agent_inst/config/prometheus/prometheusPluginConfig.json`

```json
{
  "entities": [
    {
      "namespace": "oci_prometheus_metrics",
      "metricNamespace": "container_monitoring",
      "resourceGroup": "monitoring-demo",
      "prometheusConfig": {
        "sourceUrl": "http://localhost:9090/metrics",
        "scrapeInterval": "60s",
        "scrapeTimeout": "10s"
      }
    }
  ]
}
```

### Viewing Metrics in OCI Console

**Step 1**: Navigate to OCI Monitoring
1. Go to **Observability & Management** → **Monitoring** → **Metrics Explorer**
2. Select your compartment
3. Choose namespace: **`container_monitoring`** (NOT `oci_prometheus_metrics`)

**Step 2**: Query Metrics
Available metric families:
- `container_cpu_usage_seconds_total` - CPU usage per container
- `container_memory_usage_bytes` - Memory usage per container
- `container_network_receive_bytes_total` - Network ingress
- `container_network_transmit_bytes_total` - Network egress
- `node_cpu_seconds_total` - Host CPU metrics
- `node_memory_MemAvailable_bytes` - Host memory metrics
- Custom application metrics (if exposed)

**Step 3**: Create Charts
- Use PromQL-like queries in OCI Metrics Explorer
- Set aggregation intervals (1m, 5m, 1h)
- Create alarms based on thresholds

### Verification

**Check Management Agent Status**:
```bash
# List Management Agents
oci management-agent agent list \
  --compartment-id $OCI_COMPARTMENT_OCID \
  --lifecycle-state ACTIVE \
  --query 'data[*].{"Name":"display-name","State":"lifecycle-state"}' \
  --output table
```

**Check Prometheus Plugin**:
```bash
# In Management Agent container logs, look for:
✓ Prometheus plugin configured
✓ Agent is now collecting and forwarding metrics to OCI Monitoring
```

**Verify Metrics Flow**:
```bash
# Test Prometheus endpoint
curl http://130.61.110.78:9090/metrics

# Check OCI Monitoring for recent data points
oci monitoring metric list \
  --compartment-id $OCI_COMPARTMENT_OCID \
  --namespace container_monitoring
```

### Customizing Scrape Configuration

To modify scrape intervals or add additional scrape targets, update `terraform.tfvars`:

```hcl
# Metrics Configuration
prometheus_scrape_interval  = 60   # seconds
prometheus_scrape_timeout   = 10   # seconds
metrics_namespace          = "container_monitoring"
```

Then re-apply terraform:
```bash
cd terraform
terraform apply -auto-approve
```

## 🔧 Configuration Reference

### Sidecar Architecture Variables

```bash
# Enable sidecar pattern
export ENABLE_SHARED_VOLUMES="true"

# Management Agent Sidecar
export ENABLE_MANAGEMENT_AGENT_SIDECAR="true"
export MGMT_AGENT_SIDECAR_IMAGE="fra.ocir.io/.../mgmt-agent-sidecar:1.0.0"
export MGMT_AGENT_SIDECAR_MEMORY_GB="1.0"
export MGMT_AGENT_SIDECAR_OCPUS="0.25"

# Prometheus Sidecar
export ENABLE_PROMETHEUS_SIDECAR="true"
export PROMETHEUS_SIDECAR_IMAGE="fra.ocir.io/.../prometheus-sidecar:1.0.0"
export PROMETHEUS_SIDECAR_MEMORY_GB="1.0"
export PROMETHEUS_SIDECAR_OCPUS="0.25"

# Log Forwarder Sidecar
export ENABLE_LOG_FORWARDER_SIDECAR="true"
export LOG_FORWARDER_SIDECAR_IMAGE="fra.ocir.io/.../log-forwarder-sidecar:1.0.0"
export LOG_FORWARDER_SIDECAR_MEMORY_GB="0.5"
export LOG_FORWARDER_SIDECAR_OCPUS="0.125"
```

### Prometheus Exporter Configuration

```bash
# Base exporters (always recommended)
export ENABLE_PROMETHEUS_EXPORTERS="true"  # cAdvisor + Node Exporter

# Application-specific exporters (optional)
export ENABLE_NGINX_EXPORTER="false"      # Nginx metrics
export ENABLE_REDIS_EXPORTER="false"      # Redis metrics
export ENABLE_POSTGRES_EXPORTER="false"   # PostgreSQL metrics
export ENABLE_MYSQL_EXPORTER="false"      # MySQL metrics
export ENABLE_BLACKBOX_EXPORTER="false"   # Endpoint probing
```

### Metrics Configuration

```bash
export PROMETHEUS_SCRAPE_INTERVAL="60"    # Seconds between scrapes
export PROMETHEUS_SCRAPE_TIMEOUT="10"     # Scrape timeout
export PROMETHEUS_METRICS_PORT="9090"     # Metrics endpoint port
export PROMETHEUS_METRICS_PATH="/metrics" # Metrics endpoint path
export METRICS_NAMESPACE="container_monitoring"  # OCI Monitoring namespace
```

### Logging Configuration

```bash
export ENABLE_LOGGING="true"              # Enable OCI Logging
export LOG_GROUP_NAME="container-instance-logs"
export LOG_RETENTION_DAYS="30"
export ENABLE_AUDIT_LOGS="true"
```

## 🔍 Troubleshooting

### Management Agent Not Registered

**Check container logs:**
```bash
oci container-instances container list \
  --container-instance-id <instance-id> \
  --query 'data[?contains("display-name", `mgmt-agent`)].id' \
  --raw-output | head -1 | xargs -I {} \
  oci container-instances container retrieve-logs \
  --container-id {}
```

**Common issues:**
1. **Install key expired** - Create new install key
2. **IAM policies missing** - Verify dynamic group and policies
3. **Network connectivity** - Check NSG and subnet route tables
4. **Agent already registered** - Agent persists in volume, container restart uses existing registration

### No Metrics in OCI Monitoring

**Verify Management Agent status:**
```bash
# In Management Agent sidecar container logs, look for:
✓ Management Agent registered successfully with OCI
✓ Management Agent started successfully
✓ Agent is now collecting and forwarding metrics
```

**Check Prometheus endpoint:**
```bash
# From within container instance:
curl http://localhost:9090/metrics
```

**Verify namespace:**
- Metrics appear in namespace: `container_monitoring`
- NOT in `oci_prometheus_metrics` (that's the plugin namespace)

### Logs Not Appearing in OCI Logging

**Check Log Forwarder status:**
```bash
# View log forwarder container logs
oci container-instances container list \
  --container-instance-id <instance-id> \
  --query 'data[?contains("display-name", `log-forwarder`)].id' \
  --raw-output | head -1 | xargs -I {} \
  oci container-instances container retrieve-logs \
  --container-id {}
```

**Verify log OCID:**
```bash
# Check that LOG_OCID environment variable is set in log forwarder
# It should match the application_log_ocid from logging module
```

### NSG Blocking Access

**Check your current IP:**
```bash
curl https://ifconfig.me/ip
```

**Verify NSG rules:**
```bash
oci network nsg-security-rule list \
  --network-security-group-id <nsg-id> \
  --query 'data[*].{"Direction":"direction","Source":"source","Port":"tcp-options.destination-port-range"}' \
  --output table
```

**Update NSG if IP changed:**
```bash
# Re-run terraform to update NSG with new IP
cd terraform
terraform apply -auto-approve
```

## 📈 Monitoring Best Practices

### Metric Collection
1. **Use appropriate scrape intervals**: Balance between data resolution and resource usage
2. **Configure retention**: Set appropriate retention in OCI Monitoring
3. **Use labels effectively**: Leverage container, instance, and custom labels

### Log Management
1. **Set retention policies**: Configure log retention based on compliance needs
2. **Use log levels**: Structure logs with severity levels (INFO, WARN, ERROR)
3. **Monitor log volume**: Watch for unusual log volume spikes

### Resource Allocation
1. **Sidecar sizing**: Allocate appropriate CPU/memory to sidecars
2. **Monitor sidecar health**: Check sidecar container status regularly
3. **Scale appropriately**: Increase resources if sidecars are CPU/memory constrained

### Security
1. **Rotate install keys**: Periodically rotate Management Agent install keys
2. **Review IAM policies**: Ensure least privilege access
3. **Monitor NSG rules**: Keep allowed IP addresses up to date
4. **Use Resource Principal**: Avoid hardcoded credentials

## 🛠️ Advanced Topics

### Custom Metrics

Add custom metrics to your application:

```python
from prometheus_client import Counter, Histogram, generate_latest

# Define metrics
request_count = Counter('app_requests_total', 'Total requests', ['method', 'endpoint'])
request_duration = Histogram('app_request_duration_seconds', 'Request duration')

# Instrument your code
@request_duration.time()
def handle_request():
    request_count.labels(method='GET', endpoint='/api').inc()
    # Your code here

# Expose metrics endpoint
@app.route('/metrics')
def metrics():
    return generate_latest()
```

### Multi-Instance Deployment

Scale container instances:

```bash
# In config/oci-monitoring.env
export CONTAINER_COUNT="3"  # Deploy 3 replicas
```

### Custom Dashboards

Create custom Grafana dashboards by importing JSON from OCI Monitoring:

1. Export metrics from OCI Monitoring
2. Convert to Grafana format
3. Import into Grafana instance

## 📚 Additional Resources

### OCI Documentation
- [Container Instances](https://docs.oracle.com/en-us/iaas/Content/container-instances/home.htm)
- [Management Agents](https://docs.oracle.com/en-us/iaas/management-agents/index.html)
- [OCI Monitoring](https://docs.oracle.com/en-us/iaas/Content/Monitoring/home.htm)
- [OCI Logging](https://docs.oracle.com/en-us/iaas/Content/Logging/home.htm)

### Prometheus
- [Prometheus Documentation](https://prometheus.io/docs/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Exporters and Integrations](https://prometheus.io/docs/instrumenting/exporters/)

### Related Projects
- [OCI Management Agent Quickstart](https://github.com/oracle-quickstart/oci-management-agent)
- [Prometheus Community](https://github.com/prometheus-community)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 🆘 Support

For issues and questions:
- Open an issue on GitHub: https://github.com/your-username/oci-container-monitoring-demo/issues
- Check OCI documentation
- Review troubleshooting section above

## 🎯 Roadmap

Completed:
- [x] **Grafana deployment** - Now included with pre-configured Prometheus datasource
- [x] **Official Oracle Management Agent** - Using v1.9.0 from Oracle Container Registry
- [x] **Automated registration** - ConfigFile volume with Resource Principal authentication

Future enhancements planned:
- [ ] Multi-region deployment
- [ ] Alert manager integration
- [ ] Additional custom metric dashboards
- [ ] Automated backup/restore
- [ ] HA configuration examples
- [ ] Log forwarder improvements (OCI Logging integration optimization)

## 🔖 Version History

### v2.0.0 (Current - October 2025)
- ✅ **Official Oracle Management Agent v1.9.0** - No custom builds required
- ✅ **Grafana Sidecar** - Pre-configured dashboards with Prometheus datasource
- ✅ **7 Container Architecture** - App, cAdvisor, Node Exporter, Mgmt Agent, Prometheus, Log Forwarder, Grafana
- ✅ **ConfigFile Volume** - Automatic agent registration with input.rsp
- ✅ **Resource Principal Auth** - No hardcoded credentials
- ✅ **Complete Observability Stack** - Metrics, logs, and visualization in one deployment
- ✅ **Production-ready** - Currently deployed at 130.61.110.78

### v1.0.0 (Previous)
- ✅ Sidecar-based architecture for all components
- ✅ Custom Management Agent builds (deprecated in v2.0.0)
- ✅ Log forwarding with OCI Logging integration
- ✅ NSG with automatic IP detection
- ✅ Complete Terraform automation

---

**Built with ❤️ for OCI Container Instances**

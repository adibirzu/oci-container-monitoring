# OCI Container Instance Monitoring with Prometheus

Production-ready monitoring solution for OCI Container Instances with Prometheus, Grafana, and OCI Management Agent integration.

## Overview

This solution provides comprehensive Docker/container monitoring using industry-standard tools:

- **🐳 cAdvisor**: Container-level metrics (CPU, memory, network, disk per container)
- **📊 Node Exporter**: Host-level system metrics
- **📈 Prometheus**: Time-series metrics collection and storage
- **📉 Grafana**: Rich visualization dashboards
- **☁️ OCI Management Agent**: Integration with OCI Monitoring service
- **🔒 Network Security**: NSG-based access control
- **📦 Automated Deployment**: Single-command infrastructure provisioning

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  Monitoring VM (1 OCPU, 8GB)             │
│  ┌──────────────┐  ┌────────────┐  ┌─────────────────┐ │
│  │ Management   │  │ Prometheus │  │ Grafana         │ │
│  │ Agent        │◄─┤ :9090      │◄─┤ :3000           │ │
│  │ + Prometheus │  │            │  │                 │ │
│  │   Plugin     │  │            │  │                 │ │
│  └──────┬───────┘  └─────┬──────┘  └─────────────────┘ │
│         │                 │                              │
│         ↓                 ↓ Scrapes every 15s            │
│   OCI Monitoring   Containers (Private IPs)              │
└────────────────────────────────────────────────────────┘
                             ↓
    ┌────────────────────────┼────────────────────────┐
    │                        │                        │
┌───▼────────────┐  ┌───────▼───────┐  ┌─────────▼──────┐
│ Container 1    │  │ Container 2   │  │ Container N    │
│ ├─ App         │  │ ├─ App        │  │ ├─ App         │
│ ├─ cAdvisor    │  │ ├─ cAdvisor   │  │ ├─ cAdvisor    │
│ │  :8080       │  │ │  :8080      │  │ │  :8080       │
│ └─ Node Exp.   │  │ └─ Node Exp.  │  │ └─ Node Exp.   │
│    :9100       │  │    :9100      │  │    :9100       │
└────────────────┘  └───────────────┘  └────────────────┘
```

## ✨ Features

### Comprehensive Monitoring
- ✅ Container-level metrics (per-container CPU, memory, network, disk)
- ✅ Host-level metrics (system resources, filesystem, interfaces)
- ✅ Native OCI metrics (automatic, no configuration)
- ✅ Custom application metrics (Prometheus-compatible)
- ✅ 15-second scrape interval (real-time monitoring)
- ✅ Multiple Prometheus exporters available (see below)

### Available Prometheus Exporters

This project supports multiple Prometheus exporters as sidecars for comprehensive monitoring:

**Always Available:**
- **cAdvisor** (port 8080) - Container-level metrics (CPU, memory, network, disk per container)
- **Node Exporter** (port 9100) - Host-level metrics (system resources, filesystem, network)

**Optional Application-Specific Exporters:**
- **Nginx Exporter** (port 9113) - Nginx web server metrics (connections, requests, response codes)
- **Redis Exporter** (port 9121) - Redis cache metrics (memory, keyspace, clients, commands)
- **PostgreSQL Exporter** (port 9187) - PostgreSQL database metrics (connections, transactions, locks, queries)
- **MySQL Exporter** (port 9104) - MySQL database metrics (connections, queries, InnoDB metrics)
- **Blackbox Exporter** (port 9115) - Endpoint probing (HTTP/HTTPS availability, response time, SSL validity)

**Enable specific exporters in your configuration:**
```bash
# Edit config/oci-monitoring.env
export ENABLE_PROMETHEUS_EXPORTERS="true"  # cAdvisor + Node Exporter (always recommended)
export ENABLE_NGINX_EXPORTER="true"        # If monitoring nginx
export ENABLE_REDIS_EXPORTER="true"        # If monitoring redis
export ENABLE_POSTGRES_EXPORTER="true"     # If monitoring postgres
export ENABLE_MYSQL_EXPORTER="true"        # If monitoring mysql
export ENABLE_BLACKBOX_EXPORTER="true"     # For endpoint health checks
```

### Visualization & Dashboards
- ✅ Pre-configured Grafana dashboards
- ✅ Docker container monitoring dashboard
- ✅ Prometheus health dashboard
- ✅ Customizable panels and queries
- ✅ PromQL support for advanced queries

### OCI Integration
- ✅ Management Agent sends metrics to OCI Monitoring
- ✅ Available in `oci_prometheus_metrics` namespace
- ✅ OCI Alarms integration
- ✅ Works alongside native OCI metrics

### Security
- ✅ Network Security Groups (NSG) with IP restrictions
- ✅ Monitoring VM can scrape containers securely
- ✅ Your IP has access to Grafana and Prometheus
- ✅ All other IPs blocked

### Automation
- ✅ Single-command deployment
- ✅ Automated VM provisioning with cloud-init
- ✅ Pre-configured Prometheus scraping
- ✅ Ready-to-use Grafana dashboards
- ✅ OCI Management Agent auto-configuration

## 🚀 Quick Start

### 1. Prerequisites

**System Requirements:**
- OCI CLI (v3.0+)
- Terraform (v1.5.0+)
- jq, curl
- OCI tenancy with:
  - Compartment with permissions
  - VCN and subnet
  - Management Agent Install Key

**Install on macOS:**
```bash
brew install oci-cli terraform jq
```

**Install on Linux:**
```bash
# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Install Terraform
# See: https://developer.hashicorp.com/terraform/install
```

### 2. Configure OCI CLI

```bash
oci setup config
# Follow prompts for API key, tenancy OCID, region, etc.
```

### 3. Configure Monitoring

Edit `config/oci-monitoring.env`:

```bash
# Required OCI Configuration
export TENANCY_OCID="ocid1.tenancy.oc1..aaaa..."
export COMPARTMENT_OCID="ocid1.compartment.oc1..aaaa..."
export REGION="us-ashburn-1"

# VCN Configuration
export VCN_OCID="ocid1.vcn.oc1..aaaa..."
export SUBNET_OCID="ocid1.subnet.oc1..aaaa..."

# Enable Prometheus Exporters (cAdvisor + Node Exporter)
export ENABLE_PROMETHEUS_EXPORTERS="true"

# Deploy Monitoring VM with Grafana
export DEPLOY_MONITORING_VM="true"
export ENABLE_GRAFANA="true"

# Security
export CREATE_NSG="true"
export ALLOWED_CIDR="<your-ip>/32"

# Access
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"
export GRAFANA_ADMIN_PASSWORD="YourSecurePassword123"

# Management Agent Install Key (from OCI Console)
export MGMT_AGENT_INSTALL_KEY="<your-install-key>"
```

### 4. Deploy

```bash
cd /Users/abirzu/dev/oci-monitoring

# Deploy infrastructure
./scripts/deploy.sh deploy

# Wait 10-15 minutes for:
# - Container instances with exporters
# - Monitoring VM with full stack
# - Automatic configuration
```

### 5. Access Monitoring

After deployment:

**Grafana:**
- URL: `http://<monitoring-vm-ip>:3000`
- Username: `admin`
- Password: (your configured password)
- Dashboard: Navigate to "Docker Container Monitoring"

**Prometheus:**
- URL: `http://<monitoring-vm-ip>:9090`
- Check targets: Status → Targets
- Run queries: Graph tab

**OCI Monitoring:**
- Navigate to: Observability & Management → Monitoring
- Namespace: `oci_prometheus_metrics`
- Metric Namespace: `container_monitoring`

## 📊 Monitoring Capabilities

### Metrics Collected

**From cAdvisor (Container Metrics):**
- `container_cpu_usage_seconds_total` - CPU usage per container
- `container_memory_usage_bytes` - Memory usage per container
- `container_network_receive_bytes_total` - Network RX per container
- `container_network_transmit_bytes_total` - Network TX per container
- `container_fs_reads_bytes_total` - Disk reads per container
- `container_fs_writes_bytes_total` - Disk writes per container

**From Node Exporter (Host Metrics):**
- `node_cpu_seconds_total` - CPU usage by mode (idle, user, system)
- `node_memory_*` - Memory statistics (total, available, buffers, cache)
- `node_disk_*` - Disk I/O statistics
- `node_network_*` - Network interface statistics
- `node_filesystem_*` - Filesystem usage and inodes
- `node_load*` - System load average

**From OCI Native:**
- `CpuUtilization` - Container instance CPU %
- `MemoryUtilization` - Container instance memory %
- `NetworkBytesIn/Out` - Network traffic

### Example PromQL Queries

```promql
# Container CPU usage (%)
rate(container_cpu_usage_seconds_total{image!=""}[5m]) * 100

# Container memory usage (GB)
container_memory_usage_bytes{image!=""} / 1024 / 1024 / 1024

# Node CPU usage (%)
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node memory usage (%)
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))

# Container network traffic (MB/s)
rate(container_network_receive_bytes_total{image!=""}[5m]) / 1024 / 1024
```

## 💰 Cost Analysis

### Monthly Costs (Approximate)

| Component | Configuration | Cost |
|-----------|---------------|------|
| Container Instance (with exporters) | 1 OCPU, 4GB | $10 |
| Monitoring VM | 1 OCPU, 8GB | $15 |
| **Total for 1 container** | | **$25** |
| **Total for 10 containers** | | **$115** |
| **Total for 50 containers** | | **$515** |

**Key Insight**: Monitoring VM cost ($15) is fixed, so per-container cost decreases as you scale.

### Resource Overhead Per Container

**Base Exporters (Always Enabled):**

| Component | Memory | CPU | % of 1 OCPU Instance |
|-----------|--------|-----|----------------------|
| Application | Dynamic | Dynamic | ~80% |
| cAdvisor | 500MB | 0.1 OCPU | ~8% |
| Node Exporter | 300MB | 0.1 OCPU | ~7% |
| **Base Overhead** | **800MB** | **0.2 OCPU** | **15%** |

**Optional Exporters (Enable as needed):**

| Exporter | Memory | CPU | Port |
|----------|--------|-----|------|
| Nginx Exporter | 100MB | 0.05 OCPU | 9113 |
| Redis Exporter | 100MB | 0.05 OCPU | 9121 |
| PostgreSQL Exporter | 150MB | 0.05 OCPU | 9187 |
| MySQL Exporter | 150MB | 0.05 OCPU | 9104 |
| Blackbox Exporter | 100MB | 0.05 OCPU | 9115 |
| **All Optional Combined** | **600MB** | **0.25 OCPU** | - |

**Maximum Total (if all exporters enabled):** 1.4GB memory, 0.45 OCPU overhead

## 📚 Documentation

### Comprehensive Guides

1. **[Prometheus Monitoring Guide](./docs/PROMETHEUS_MONITORING_GUIDE.md)**
   - Complete setup and configuration
   - All components explained in detail
   - PromQL query examples
   - Troubleshooting procedures
   - Maintenance guides

2. **[Container Instance Monitoring](./docs/CONTAINER_INSTANCE_MONITORING.md)**
   - Native metrics vs Prometheus comparison
   - Use case recommendations
   - Architecture options

3. **[Prometheus Enhancement Summary](./PROMETHEUS_ENHANCEMENT_SUMMARY.md)**
   - What was implemented
   - Configuration changes
   - Testing procedures

4. **[Architecture Guide](./docs/ARCHITECTURE_GUIDE.md)**
   - Architecture patterns
   - Deployment scenarios
   - Migration paths

### Quick References

- **[Container Logs](./docs/CONTAINER_LOGS.md)** - Logging configuration
- **[Quickstart Guide](./docs/QUICKSTART.md)** - Fast deployment guide
- **[Troubleshooting](./docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🔧 Configuration Options

### Monitoring Options

```bash
# Enable/disable Prometheus exporters (cAdvisor + Node Exporter)
export ENABLE_PROMETHEUS_EXPORTERS="true"  # Default: true

# Deploy centralized Monitoring VM
export DEPLOY_MONITORING_VM="true"  # Default: false

# Enable Grafana dashboards
export ENABLE_GRAFANA="true"  # Default: false

# Prometheus scrape interval
export PROMETHEUS_SCRAPE_INTERVAL="15"  # Default: 15 seconds
```

### Security Options

```bash
# Create Network Security Groups
export CREATE_NSG="true"

# Allowed IP CIDR (your IP only)
export ALLOWED_CIDR="1.2.3.4/32"

# SSH public key for VM access
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)"
```

### Container Options

```bash
# Container configuration
export CONTAINER_IMAGE="nginx:latest"
export CONTAINER_OCPUS="1"
export CONTAINER_MEMORY_GB="4"
export CONTAINER_PORT="80"

# Container environment variables
export CONTAINER_ENV_VARS="ENV=production,DEBUG=false"
```

## 🛠️ Common Tasks

### View Metrics in Grafana

```bash
# Get Monitoring VM IP
cd terraform
terraform output monitoring_vm_public_ip

# Open browser
# http://<vm-ip>:3000
# Login: admin / <your-password>
# Navigate: Dashboards → Browse → Docker Container Monitoring
```

### Query Prometheus

```bash
# Access Prometheus UI
# http://<vm-ip>:9090

# Or query via API
curl "http://<vm-ip>:9090/api/v1/query?query=up"
```

### Check Scraping Status

```bash
# SSH to Monitoring VM
ssh opc@<vm-ip>

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job, instance, health}'

# Check Prometheus logs
sudo journalctl -u prometheus -f

# Check Grafana logs
sudo journalctl -u grafana-server -f

# Check Management Agent logs
sudo journalctl -u mgmt_agent -f
```

### Update Container Instances

```bash
# Edit configuration
vi config/oci-monitoring.env

# Apply changes
./scripts/deploy.sh deploy
```

### Destroy All Resources

```bash
./scripts/deploy.sh destroy
```

## 🔍 Troubleshooting

### Exporters Not Scraping

```bash
# Check cAdvisor is running
oci container-instances container list --container-instance-id <instance-id>

# Test cAdvisor metrics endpoint
curl http://<container-ip>:8080/metrics

# Test Node Exporter metrics endpoint
curl http://<container-ip>:9100/metrics
```

### Prometheus Not Collecting

```bash
# SSH to Monitoring VM
ssh opc@<vm-ip>

# Check Prometheus status
sudo systemctl status prometheus

# View Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Prometheus config
cat /etc/prometheus/prometheus.yml
```

### Grafana Not Showing Data

```bash
# Check Grafana data source
curl http://admin:<password>@localhost:3000/api/datasources

# Verify Prometheus is reachable
curl http://localhost:9090/api/v1/query?query=up

# Restart Grafana
sudo systemctl restart grafana-server
```

See **[Troubleshooting Guide](./docs/TROUBLESHOOTING.md)** for more solutions.

## 🌟 Key Advantages

### vs Native OCI Metrics Only

| Feature | Native Only | + Prometheus |
|---------|-------------|--------------|
| Per-container metrics | ❌ | ✅ |
| Host-level metrics | ❌ | ✅ |
| Custom dashboards | ❌ | ✅ |
| Historical data | 90 days | Unlimited |
| Scrape interval | Varies | 15 seconds |
| Visualization | OCI Console | Grafana + OCI |

### vs Management Agent Sidecar

- ✅ **Actually works** (agent sidecars fail in containers)
- ✅ **Industry standard** (Prometheus + Grafana)
- ✅ **More metrics** (cAdvisor + Node Exporter)
- ✅ **Better visualization** (Grafana dashboards)
- ✅ **Scalable** (single VM monitors all containers)

## 📞 Support

For issues or questions:

1. Check **[Troubleshooting Guide](./docs/TROUBLESHOOTING.md)**
2. Review **[Prometheus Monitoring Guide](./docs/PROMETHEUS_MONITORING_GUIDE.md)**
3. Check Prometheus/Grafana logs
4. Verify NSG rules and networking

## 📝 License

This project is provided as-is for use within your organization.

## 📅 Version

- **Version**: 2.0.0 (Prometheus-based)
- **Last Updated**: 2025
- **Stack**: Prometheus + Grafana + OCI Management Agent

---

**Ready to deploy?** Start with the [Quick Start](#-quick-start) guide above!

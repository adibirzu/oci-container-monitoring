# OCI Container Instance Monitoring - End-to-End Architecture

## Overview

This is a production-ready, comprehensive monitoring solution for OCI Container Instances using the **sidecar pattern** with Management Agent and Prometheus exporters running alongside application containers.

## Architecture Pattern

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OCI Container Instance                           │
│                     (CI.Standard.E4.Flex)                           │
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐ │
│  │  Application     │  │  Management      │  │  Prometheus     │ │
│  │  Container       │  │  Agent Sidecar   │  │  Sidecar        │ │
│  │                  │  │                  │  │                 │ │
│  │  - Nginx         │  │  - Scrapes       │  │  - cAdvisor     │ │
│  │  - App Server    │  │    Prometheus    │  │  - Node Exp.    │ │
│  │  - Metrics :9090 │  │  - Sends to OCI  │  │  - App Metrics  │ │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬────────┘ │
│           │                     │                      │          │
│           └─────────────────────┼──────────────────────┘          │
│                                 │                                 │
│                    Shared Volume: /metrics                        │
│                    Shared Volume: /logs                           │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ↓
                          OCI Monitoring Service
                          (oci_prometheus_metrics namespace)
```

## Key Components

### 1. Application Container
- **Base Image**: `nginx:latest` or custom app image
- **Purpose**: Main application workload
- **Exposes**: Application metrics on `/metrics` endpoint
- **Volumes**:
  - `/metrics` - Shared metrics directory
  - `/logs` - Application logs

### 2. Management Agent Sidecar
- **Base Image**: `container-registry.oracle.com/os/oraclelinux:8`
- **Purpose**: Collect metrics and send to OCI Monitoring
- **Features**:
  - Installs OCI Management Agent
  - Configured with Prometheus plugin
  - Scrapes local Prometheus endpoints
  - Sends to `oci_prometheus_metrics` namespace
- **Volumes**:
  - `/metrics` - Read metrics from other containers
  - `/opt/oracle/mgmt_agent` - Agent data

### 3. Prometheus Exporters Sidecar
- **cAdvisor** (port 8080): Container-level metrics
- **Node Exporter** (port 9100): Host-level metrics
- **Application Exporters** (optional):
  - Nginx Exporter (port 9113)
  - Redis Exporter (port 9121)
  - PostgreSQL Exporter (port 9187)
  - MySQL Exporter (port 9104)
  - Blackbox Exporter (port 9115)

## Sidecar Communication Pattern

### Metrics Flow

```
Application Container
    ↓ (exposes :9090/metrics)
    ↓
Prometheus Exporters
    ↓ (scrapes and aggregates)
    ↓
Shared Volume (/metrics)
    ↓
Management Agent
    ↓ (reads and forwards)
    ↓
OCI Monitoring Service
```

### Volume Sharing

All containers share two volumes:

1. **Metrics Volume** (`/metrics`):
   - Application writes metrics files
   - Prometheus writes aggregated metrics
   - Management Agent reads and forwards

2. **Logs Volume** (`/logs`):
   - Application logs
   - Agent logs
   - Exporter logs

## Resource Allocation

For a 4GB, 1 OCPU instance:

| Container | Memory | vCPU | Purpose |
|-----------|--------|------|---------|
| Application | 2.0 GB | 0.5 | Main workload |
| Management Agent | 1.0 GB | 0.25 | Metrics forwarding |
| Prometheus Exporters | 1.0 GB | 0.25 | Metrics collection |
| **Total** | **4.0 GB** | **1.0** | Full utilization |

## Network & Security

### Network Security Groups (NSG)

**Container Instance NSG**:
- Port 80/443: HTTP/HTTPS (from allowed CIDR)
- Port 8080: cAdvisor (from monitoring VM)
- Port 9090: Prometheus (from monitoring VM)
- Port 9100: Node Exporter (from monitoring VM)
- Port 9113: Nginx Exporter (from monitoring VM)
- Port 9121: Redis Exporter (from monitoring VM)
- Port 9187: PostgreSQL Exporter (from monitoring VM)
- Port 9104: MySQL Exporter (from monitoring VM)
- Port 9115: Blackbox Exporter (from monitoring VM)

### IAM Policies

**Dynamic Groups**:
1. `container-instance-dg`: All container instances
2. `management-agent-dg`: All management agents

**Policies**:
```
Allow dynamic-group container-instance-dg to use metrics in compartment
Allow dynamic-group management-agent-dg to use metrics in compartment
Allow dynamic-group management-agent-dg to read log-groups in compartment
```

## Monitoring Stack

### Centralized Monitoring VM (Optional)

For multiple container instances, deploy a monitoring VM with:

- **Prometheus Server**: Aggregates metrics from all containers
- **Grafana**: Visualization dashboards
- **Alertmanager**: Alert routing and notification

```
┌────────────────────────────────────────┐
│     Monitoring VM (1 OCPU, 8GB)       │
│  ┌──────────┐  ┌──────────────────┐  │
│  │Prometheus│◄─┤  Grafana :3000   │  │
│  │  :9090   │  │  - Dashboards    │  │
│  └────┬─────┘  └──────────────────┘  │
└───────┼────────────────────────────────┘
        │ Scrapes every 15s
        ↓
    Container Instances
    (with exporters)
```

## Deployment Flow

### 1. Build Custom Images (Optional)

```bash
cd docker/management-agent
docker build -t your-region.ocir.io/namespace/mgmt-agent:latest .
docker push your-region.ocir.io/namespace/mgmt-agent:latest
```

### 2. Configure Environment

Edit `config/oci-monitoring.env`:

```bash
# Enable all monitoring components
export ENABLE_PROMETHEUS_EXPORTERS="true"
export ENABLE_MANAGEMENT_AGENT_SIDECAR="true"
export ENABLE_SHARED_VOLUMES="true"

# Optional exporters
export ENABLE_NGINX_EXPORTER="true"
export ENABLE_REDIS_EXPORTER="false"
export ENABLE_POSTGRES_EXPORTER="false"
export ENABLE_MYSQL_EXPORTER="false"
export ENABLE_BLACKBOX_EXPORTER="true"
```

### 3. Deploy Infrastructure

```bash
./scripts/deploy.sh deploy
```

### 4. Verify Deployment

```bash
# Check container instance
oci container-instances container-instance get \
  --container-instance-id <instance-id>

# List all containers
oci container-instances container list \
  --container-instance-id <instance-id>

# Expected containers:
# - app-container
# - management-agent-sidecar
# - cadvisor-sidecar
# - node-exporter-sidecar
# - [optional exporters]
```

## Metrics Available

### From Application Container
- Custom application metrics
- HTTP request rates, latencies
- Business metrics

### From cAdvisor
- Per-container CPU usage
- Per-container memory usage
- Network I/O per container
- Disk I/O per container

### From Node Exporter
- Host CPU usage (all cores)
- Host memory statistics
- Filesystem usage
- Network interface statistics

### From Application Exporters (Optional)
- **Nginx**: Connections, requests, response codes
- **Redis**: Memory, keyspace, commands
- **PostgreSQL**: Connections, queries, locks
- **MySQL**: Connections, queries, InnoDB
- **Blackbox**: HTTP/HTTPS probes, SSL validation

## OCI Monitoring Integration

All metrics are sent to OCI Monitoring under:
- **Namespace**: `oci_prometheus_metrics`
- **Metric Namespace**: `container_monitoring`
- **Resource Group**: `<container-instance-name>`

Access in OCI Console:
1. Navigate to **Observability & Management** → **Monitoring**
2. Select **Metrics Explorer**
3. Choose namespace: `oci_prometheus_metrics`
4. Query and visualize metrics

## High Availability & Scaling

### Single Container Instance
- Restart policy: `ALWAYS` or `ON_FAILURE`
- Health checks on all containers
- Graceful shutdown: 30 seconds

### Multiple Container Instances
- Deploy multiple instances across ADs
- Load balancer for traffic distribution
- Centralized Prometheus aggregates all metrics
- Single Grafana for unified dashboards

## Cost Optimization

### Minimal Setup (1 Container Instance)
- Instance: $10/month (1 OCPU, 4GB)
- **Total: $10/month**

### Production Setup (10 Instances + Monitoring VM)
- Instances: 10 × $10 = $100/month
- Monitoring VM: $15/month (1 OCPU, 8GB)
- **Total: $115/month**

### Cost per Container Decreases with Scale
- 1 container: $10/container
- 10 containers: $11.50/container
- 50 containers: $10.30/container

## Troubleshooting

### Management Agent Not Registering

**Issue**: Agent sidecar not visible in OCI Console

**Solution**: Check agent logs:
```bash
oci container-instances container retrieve-logs \
  --container-instance-id <id> \
  --container-name management-agent-sidecar
```

### Metrics Not Flowing

**Check 1**: Verify Prometheus exporters are running
```bash
curl http://<container-ip>:8080/metrics  # cAdvisor
curl http://<container-ip>:9100/metrics  # Node Exporter
```

**Check 2**: Verify Management Agent configuration
```bash
# SSH to container (if debugging enabled)
cat /opt/oracle/mgmt_agent/agent_inst/config/prometheus/prometheusPluginConfig.json
```

**Check 3**: Check OCI Monitoring for metrics
- Navigate to Metrics Explorer
- Look for `oci_prometheus_metrics` namespace

### High Resource Usage

**Symptom**: Containers running out of memory

**Solutions**:
1. Increase instance size (2 OCPU, 8GB)
2. Disable unused exporters
3. Reduce scrape frequency
4. Optimize application metrics cardinality

## Best Practices

### 1. Resource Allocation
- ✅ Allocate at least 40% to application
- ✅ Reserve 30% for Management Agent
- ✅ Reserve 30% for exporters

### 2. Volume Management
- ✅ Use shared volumes for metrics exchange
- ✅ Implement log rotation
- ✅ Clean up old metrics files

### 3. Security
- ✅ Use NSG for network isolation
- ✅ Implement least-privilege IAM
- ✅ Use private subnets where possible
- ✅ Enable encryption at rest

### 4. Monitoring
- ✅ Set up OCI Alarms for critical metrics
- ✅ Configure notification topics
- ✅ Create Grafana dashboards
- ✅ Test alert workflows

### 5. Operations
- ✅ Implement health checks on all containers
- ✅ Use meaningful container names
- ✅ Tag resources for cost tracking
- ✅ Document custom metrics

## Migration Path

### From VM-Based Monitoring
1. Deploy container instances with sidecars
2. Point Prometheus to scrape containers
3. Migrate dashboards to new data sources
4. Decommission VMs

### From Basic OCI Monitoring
1. Keep native metrics (always free)
2. Add Prometheus exporters for detailed metrics
3. Add Management Agent for OCI integration
4. Build custom dashboards

## Support & Maintenance

### Regular Tasks
- **Daily**: Check OCI Alarms
- **Weekly**: Review Grafana dashboards
- **Monthly**: Analyze costs, optimize resources
- **Quarterly**: Update container images, review security

### Upgrades
- Management Agent: Auto-updates via OCI
- Prometheus Exporters: Manual image updates
- Application: CI/CD pipeline updates

## References

- [OCI Container Instances Documentation](https://docs.oracle.com/en-us/iaas/Content/container-instances/home.htm)
- [OCI Management Agent Documentation](https://docs.oracle.com/en-us/iaas/management-agents/index.html)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [cAdvisor Documentation](https://github.com/google/cadvisor)

---

**Version**: 3.0.0
**Last Updated**: 2025-10-28
**Architecture**: Sidecar-based with Management Agent + Prometheus
**Status**: Production-Ready

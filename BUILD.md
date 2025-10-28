# Building and Deploying Custom Container Images

## Overview

This guide explains how to build and deploy the custom container images for the OCI Container Instance Monitoring solution.

## Prerequisites

### Required Tools
- Docker (20.10+)
- OCI CLI configured
- Access to Oracle Container Image Registry (OCIR)

### OCI Setup
1. **Create Auth Token** (for OCIR push):
   ```bash
   oci iam auth-token create \
     --user-id <your-user-ocid> \
     --description "OCIR Push Token"
   ```

2. **Get your tenancy namespace**:
   ```bash
   oci os ns get
   ```

3. **Login to OCIR**:
   ```bash
   docker login <region-key>.ocir.io
   # Username: <tenancy-namespace>/<username>
   # Password: <auth-token>
   ```

## Build Instructions

### 1. Management Agent Sidecar

```bash
cd docker/management-agent

# Build
docker build -t mgmt-agent-sidecar:1.0.0 .

# Tag for OCIR
docker tag mgmt-agent-sidecar:1.0.0 \
  <region-key>.ocir.io/<namespace>/oci-monitoring/mgmt-agent-sidecar:1.0.0

# Push to OCIR
docker push <region-key>.ocir.io/<namespace>/oci-monitoring/mgmt-agent-sidecar:1.0.0
```

### 2. Prometheus Sidecar

```bash
cd docker/prometheus

# Build
docker build -t prometheus-sidecar:1.0.0 .

# Tag for OCIR
docker tag prometheus-sidecar:1.0.0 \
  <region-key>.ocir.io/<namespace>/oci-monitoring/prometheus-sidecar:1.0.0

# Push to OCIR
docker push <region-key>.ocir.io/<namespace>/oci-monitoring/prometheus-sidecar:1.0.0
```

### 3. Application with Metrics

```bash
cd docker/app-with-metrics

# Build
docker build -t app-with-metrics:1.0.0 .

# Tag for OCIR
docker tag app-with-metrics:1.0.0 \
  <region-key>.ocir.io/<namespace>/oci-monitoring/app-with-metrics:1.0.0

# Push to OCIR
docker push <region-key>.ocir.io/<namespace>/oci-monitoring/app-with-metrics:1.0.0
```

## Automated Build Script

Create a `build-all.sh` script:

```bash
#!/bin/bash
set -e

REGION_KEY="fra"  # Frankfurt
NAMESPACE="your-tenancy-namespace"
VERSION="1.0.0"

OCIR_URL="${REGION_KEY}.ocir.io/${NAMESPACE}/oci-monitoring"

echo "Building all images..."

# Management Agent
echo "Building Management Agent Sidecar..."
cd docker/management-agent
docker build -t mgmt-agent-sidecar:${VERSION} .
docker tag mgmt-agent-sidecar:${VERSION} ${OCIR_URL}/mgmt-agent-sidecar:${VERSION}
docker push ${OCIR_URL}/mgmt-agent-sidecar:${VERSION}

# Prometheus
echo "Building Prometheus Sidecar..."
cd ../prometheus
docker build -t prometheus-sidecar:${VERSION} .
docker tag prometheus-sidecar:${VERSION} ${OCIR_URL}/prometheus-sidecar:${VERSION}
docker push ${OCIR_URL}/prometheus-sidecar:${VERSION}

# Application
echo "Building Application with Metrics..."
cd ../app-with-metrics
docker build -t app-with-metrics:${VERSION} .
docker tag app-with-metrics:${VERSION} ${OCIR_URL}/app-with-metrics:${VERSION}
docker push ${OCIR_URL}/app-with-metrics:${VERSION}

echo "All images built and pushed successfully!"
```

Make it executable:
```bash
chmod +x build-all.sh
./build-all.sh
```

## Using Images in Terraform

Update your `config/oci-monitoring.env`:

```bash
# Custom image URLs from OCIR
export CONTAINER_IMAGE="fra.ocir.io/<namespace>/oci-monitoring/app-with-metrics:1.0.0"
export MGMT_AGENT_IMAGE="fra.ocir.io/<namespace>/oci-monitoring/mgmt-agent-sidecar:1.0.0"
export PROMETHEUS_IMAGE="fra.ocir.io/<namespace>/oci-monitoring/prometheus-sidecar:1.0.0"

# OCIR authentication
export OCIR_USERNAME="<namespace>/<username>"
export OCIR_AUTH_TOKEN="<your-auth-token>"
export OCIR_REGION="fra"
```

## Image Registry Setup

### Make Repository Public (Optional)

If you want to avoid authentication:

```bash
oci artifacts container repository update \
  --repository-id <repository-ocid> \
  --is-public true
```

### Or Configure Image Pull Secret

The Terraform module automatically configures image pull secrets if you provide:
- `OCIR_USERNAME`
- `OCIR_AUTH_TOKEN`

## Testing Images Locally

### Test Management Agent

```bash
docker run -it --rm \
  -e MGMT_AGENT_INSTALL_KEY="your-install-key" \
  -e OCI_REGION="us-ashburn-1" \
  -v /tmp/metrics:/metrics \
  -v /tmp/logs:/logs \
  mgmt-agent-sidecar:1.0.0
```

### Test Prometheus

```bash
docker run -it --rm \
  -p 9090:9090 \
  -v /tmp/metrics:/metrics \
  prometheus-sidecar:1.0.0
```

### Test Application

```bash
docker run -it --rm \
  -p 80:80 \
  -p 8081:8081 \
  -v /tmp/metrics:/metrics \
  -v /tmp/logs:/logs \
  app-with-metrics:1.0.0
```

Then access:
- Application: http://localhost
- Metrics: http://localhost:8081/metrics

## Multi-Architecture Builds

For ARM and x86 support:

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ${OCIR_URL}/app-with-metrics:${VERSION} \
  --push .
```

## Image Versioning

### Tagging Strategy

```bash
# Version tag
docker tag app-with-metrics:1.0.0 ${OCIR_URL}/app-with-metrics:1.0.0

# Latest tag
docker tag app-with-metrics:1.0.0 ${OCIR_URL}/app-with-metrics:latest

# Push both
docker push ${OCIR_URL}/app-with-metrics:1.0.0
docker push ${OCIR_URL}/app-with-metrics:latest
```

## Troubleshooting

### Authentication Failed

```bash
# Verify OCI CLI configuration
oci iam region list

# Test OCIR login
echo "<auth-token>" | docker login -u '<namespace>/<username>' --password-stdin <region>.ocir.io
```

### Push Failed - Repository Doesn't Exist

Create repository first:

```bash
oci artifacts container repository create \
  --compartment-id <compartment-ocid> \
  --display-name "oci-monitoring/app-with-metrics"
```

### Image Too Large

Optimize Dockerfile:
- Use multi-stage builds
- Clean up package caches
- Use `.dockerignore`

### Permission Denied

Ensure your OCI user has:
- `REPOSITORY_CREATE`
- `REPOSITORY_UPDATE`
- `REPOSITORY_READ`
- `REPOSITORY_DELETE`

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Push to OCIR

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Login to OCIR
        run: |
          echo "${{ secrets.OCIR_TOKEN }}" | docker login -u "${{ secrets.OCIR_USERNAME }}" --password-stdin fra.ocir.io

      - name: Build and Push
        run: |
          ./build-all.sh
```

## Image Security

### Scan for Vulnerabilities

```bash
# Using Docker Scout
docker scout cves mgmt-agent-sidecar:1.0.0

# Using Trivy
trivy image mgmt-agent-sidecar:1.0.0
```

### Sign Images (Optional)

```bash
# Using Docker Content Trust
export DOCKER_CONTENT_TRUST=1
docker push ${OCIR_URL}/app-with-metrics:1.0.0
```

## Next Steps

After building and pushing images:

1. Update Terraform variables with image URLs
2. Deploy infrastructure: `./scripts/deploy.sh deploy`
3. Verify containers are running
4. Check metrics in OCI Monitoring

---

**Version**: 1.0.0
**Last Updated**: 2025-10-28
**Docker Version**: 20.10+
**OCI CLI Version**: 3.0+

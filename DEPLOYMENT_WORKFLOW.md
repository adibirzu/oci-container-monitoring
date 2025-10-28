# OCI Monitoring - Deployment Workflow

## 🚨 Issue Encountered

**Error**: "A container's image could not be pulled because the image does not exist or requires authorization."

**Root Cause**: The configuration had sidecar features enabled, but the custom Docker images haven't been built and pushed to OCIR yet.

**Solution**: Disable sidecars temporarily until images are built.

## ✅ Current Configuration Status

The configuration has been updated to use **Legacy Architecture** until sidecar images are ready:

```bash
# In config/oci-monitoring.env:
ENABLE_MANAGEMENT_AGENT="true"              # ✅ Legacy agent enabled
ENABLE_SHARED_VOLUMES="false"               # ❌ Sidecars disabled
ENABLE_MANAGEMENT_AGENT_SIDECAR="false"     # ❌ Sidecars disabled
ENABLE_PROMETHEUS_SIDECAR="false"           # ❌ Sidecars disabled
```

## 📋 Deployment Options

You have **two deployment options**:

---

### Option 1: Deploy Legacy Architecture (Current - Fastest)

**Use this if**: You want to deploy quickly with the existing public images.

**Advantages**:
- ✅ Works immediately (uses public `nginx:latest`)
- ✅ No image building required
- ✅ No OCIR authentication needed

**Disadvantages**:
- ❌ No sidecar pattern benefits
- ❌ Legacy Management Agent approach
- ❌ No shared volumes

**Deploy Command**:
```bash
# Already configured - just deploy
./scripts/deploy.sh deploy
```

**Architecture**:
```
┌─────────────────────────────────────┐
│    OCI Container Instance           │
│  ┌──────────┐  ┌─────────────────┐ │
│  │   App    │  │ Mgmt Agent      │ │
│  │ (nginx)  │  │ (Legacy)        │ │
│  └──────────┘  └─────────────────┘ │
└─────────────────────────────────────┘
```

---

### Option 2: Deploy Sidecar Architecture (Recommended - Requires Setup)

**Use this if**: You want the full production-ready sidecar architecture.

**Advantages**:
- ✅ Modern sidecar pattern
- ✅ Shared volumes for metrics/logs
- ✅ Prometheus aggregation
- ✅ Better resource isolation

**Disadvantages**:
- ❌ Requires building Docker images (~30 min)
- ❌ Requires OCIR authentication
- ❌ Requires updating configuration

**Steps**:

#### Step 1: Get Your OCIR Namespace
```bash
oci os ns get
# Example output: frxyz1a2b3c4
```

#### Step 2: Create OCIR Auth Token
1. Go to OCI Console → Profile → Auth Tokens
2. Click "Generate Token"
3. Give it a name: "OCIR Docker Push"
4. **Copy the token** (you won't see it again!)

#### Step 3: Update Configuration
Edit `config/oci-monitoring.env`:

```bash
# OCIR Configuration
export OCIR_NAMESPACE="YOUR_NAMESPACE_HERE"      # From Step 1
export OCIR_USERNAME="YOUR_NAMESPACE/YOUR_EMAIL"  # e.g., frxyz1a2b3c4/alex@example.com
export OCIR_PASSWORD="YOUR_AUTH_TOKEN_HERE"      # From Step 2
```

#### Step 4: Build and Push Docker Images
```bash
cd docker
./build-all.sh

# This will:
# 1. Login to OCIR
# 2. Build 3 custom images
# 3. Push to your OCIR registry
# Takes: ~15-30 minutes
```

**Expected Output**:
```
Building Management Agent Sidecar...
✓ Management Agent Sidecar pushed successfully

Building Prometheus Sidecar...
✓ Prometheus Sidecar pushed successfully

Building Application with Metrics...
✓ Application with Metrics pushed successfully

Update your config/oci-monitoring.env with:
  export MGMT_AGENT_SIDECAR_IMAGE="fra.ocir.io/YOUR_NS/oci-monitoring/mgmt-agent-sidecar:1.0.0"
  export PROMETHEUS_SIDECAR_IMAGE="fra.ocir.io/YOUR_NS/oci-monitoring/prometheus-sidecar:1.0.0"
  export APP_WITH_METRICS_IMAGE="fra.ocir.io/YOUR_NS/oci-monitoring/app-with-metrics:1.0.0"
```

#### Step 5: Enable Sidecars in Configuration
Edit `config/oci-monitoring.env`:

```bash
# Disable legacy
export ENABLE_MANAGEMENT_AGENT="false"

# Enable sidecar architecture
export ENABLE_SHARED_VOLUMES="true"
export ENABLE_MANAGEMENT_AGENT_SIDECAR="true"
export ENABLE_PROMETHEUS_SIDECAR="true"

# Update image URLs (from Step 4 output)
export MGMT_AGENT_SIDECAR_IMAGE="fra.ocir.io/YOUR_NS/oci-monitoring/mgmt-agent-sidecar:1.0.0"
export PROMETHEUS_SIDECAR_IMAGE="fra.ocir.io/YOUR_NS/oci-monitoring/prometheus-sidecar:1.0.0"
export CONTAINER_IMAGE="fra.ocir.io/YOUR_NS/oci-monitoring/app-with-metrics:1.0.0"

# Update OCIR credentials for image pulling
export OCIR_USERNAME="YOUR_NAMESPACE/YOUR_EMAIL"
export OCIR_AUTH_TOKEN="YOUR_AUTH_TOKEN"
```

#### Step 6: Deploy with Sidecars
```bash
cd /Users/abirzu/dev/oci-monitoring
./scripts/deploy.sh deploy
```

**Architecture**:
```
┌──────────────────────────────────────────────┐
│         OCI Container Instance               │
│  ┌────────┐  ┌──────────┐  ┌──────────────┐ │
│  │  App   │  │Prometheus│  │  Mgmt Agent  │ │
│  │        │  │ Sidecar  │  │   Sidecar    │ │
│  └───┬────┘  └─────┬────┘  └──────┬───────┘ │
│      └─────────────┼───────────────┘         │
│        Shared Volumes: /metrics, /logs       │
└──────────────────────────────────────────────┘
```

---

## 🔍 Verification

### Check Container Instance Status
```bash
oci container-instances container-instance get \
  --container-instance-id $(terraform output -raw container_instance_id)
```

### List All Containers
```bash
oci container-instances container list \
  --container-instance-id $(terraform output -raw container_instance_id) \
  --compartment-id <your-compartment-id>
```

**Legacy Architecture - You'll see**:
- `monitoring-demo-app` (nginx)
- `monitoring-demo-agent` (legacy)

**Sidecar Architecture - You'll see**:
- `monitoring-demo-app` (custom app with metrics)
- `monitoring-demo-mgmt-agent-sidecar`
- `monitoring-demo-prometheus-sidecar`
- Plus optional exporters (cAdvisor, Node Exporter, etc.)

### Access the Application
```bash
# Get public IP
PUBLIC_IP=$(terraform output -raw container_public_ip)

# Test application
curl http://$PUBLIC_IP

# Test metrics endpoint (sidecar only)
curl http://$PUBLIC_IP/metrics
```

---

## 🐛 Troubleshooting

### Issue: "Image could not be pulled"

**Cause**: Trying to deploy sidecars without building images first.

**Solution**:
```bash
# Option A: Disable sidecars (use legacy)
# Edit config/oci-monitoring.env:
export ENABLE_SHARED_VOLUMES="false"
export ENABLE_MANAGEMENT_AGENT_SIDECAR="false"
export ENABLE_PROMETHEUS_SIDECAR="false"
export ENABLE_MANAGEMENT_AGENT="true"

# Option B: Build the images first
cd docker && ./build-all.sh
```

### Issue: "OCIR authentication failed"

**Cause**: Invalid or missing OCIR credentials.

**Solution**:
1. Verify auth token is correct
2. Check username format: `<namespace>/<email>`
3. Try manual login:
   ```bash
   docker login fra.ocir.io
   # Username: <namespace>/<email>
   # Password: <auth-token>
   ```

### Issue: Images built but still failing to pull

**Cause**: Image URLs in config don't match actual OCIR URLs.

**Solution**:
1. List your images:
   ```bash
   oci artifacts container image list \
     --compartment-id <compartment-id> \
     --repository-name "oci-monitoring/*"
   ```
2. Copy exact URLs to `config/oci-monitoring.env`

---

## 📊 Resource Requirements

### Legacy Architecture
| Component | Memory | CPU | Total |
|-----------|--------|-----|-------|
| Application | 2.8 GB | 0.7 | 2.8 GB / 0.7 CPU |
| Management Agent | 1.2 GB | 0.3 | - |
| **Total** | **4.0 GB** | **1.0** | Instance minimum |

### Sidecar Architecture
| Component | Memory | CPU | Total |
|-----------|--------|-----|-------|
| Application | 1.5 GB | 0.5 | 4.0 GB / 1.0 CPU |
| Prometheus Sidecar | 1.0 GB | 0.25 | - |
| Mgmt Agent Sidecar | 1.0 GB | 0.25 | - |
| cAdvisor | 0.5 GB | 0.1 | - |
| **Total** | **4.0 GB** | **1.1** | Adjust instance size |

**Note**: For sidecar architecture, consider using `CONTAINER_OCPUS=2` and `CONTAINER_MEMORY_GB=8`.

---

## 📚 Related Documentation

- **QUICKSTART.md** - Quick deployment guide
- **BUILD.md** - Detailed image building instructions
- **ARCHITECTURE.md** - Complete architecture documentation
- **FIXES_APPLIED.md** - Recent Terraform fixes
- **IMPLEMENTATION_STATUS.md** - Overall implementation progress

---

## 🎯 Recommended Path

**For immediate deployment**: Use **Option 1** (Legacy Architecture)
**For production use**: Use **Option 2** (Sidecar Architecture)

### Quick Decision Guide

**Choose Legacy if you need**:
- Quick deployment (<5 minutes)
- Simple architecture
- No custom image requirements

**Choose Sidecar if you want**:
- Production-ready monitoring
- Better resource isolation
- Shared volumes for logs/metrics
- Prometheus aggregation
- Full observability stack

---

**Last Updated**: 2025-10-28
**Status**: Configuration fixed, ready for deployment
**Next Step**: Choose deployment option and follow steps above
